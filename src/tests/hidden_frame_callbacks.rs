use std::sync::atomic::Ordering;

use client::ClientId;
use niri_config::Config;
use wayland_client::protocol::wl_surface::WlSurface;

use super::*;

const RULE: &str = r##"
window-rule {
    match app-id="^relay$"
    frame-callbacks-when-hidden true
}
"##;

// One output, one mapped 100×100 window with the given app-id, monitors powered off.
fn set_up(app_id: &str) -> (Fixture, ClientId, WlSurface) {
    let config = Config::parse_mem(RULE).unwrap();
    let mut f = Fixture::with_config(config);
    f.add_output(1, (1920, 1080));

    let id = f.add_client();
    let window = f.client(id).create_window();
    let surface = window.surface.clone();
    window.set_app_id(app_id);
    window.commit();
    f.roundtrip(id);

    let window = f.client(id).window(&surface);
    window.attach_new_buffer();
    window.set_size(100, 100);
    window.ack_last_and_commit();
    f.double_roundtrip(id);

    let state = f.niri_state();
    state.niri.deactivate_monitors(&mut state.backend);

    (f, id, surface)
}

#[test]
fn rule_keeps_frame_callbacks_with_monitors_off() {
    let (mut f, id, surface) = set_up("relay");

    let window = f.client(id).window(&surface);
    let frame = window.frame();
    window.commit();
    f.double_roundtrip(id);
    assert!(!frame.done.load(Ordering::Relaxed));

    assert!(f.niri().send_frame_callbacks_to_hidden_windows());
    f.double_roundtrip(id);
    assert!(frame.done.load(Ordering::Relaxed));
}

#[test]
fn no_frame_callbacks_without_rule() {
    let (mut f, id, surface) = set_up("other");

    let window = f.client(id).window(&surface);
    let frame = window.frame();
    window.commit();
    f.double_roundtrip(id);

    assert!(!f.niri().send_frame_callbacks_to_hidden_windows());
    f.double_roundtrip(id);
    assert!(!frame.done.load(Ordering::Relaxed));
}

#[test]
fn rule_follows_app_id_set_after_mapping() {
    let (mut f, id, surface) = set_up("other");
    assert!(!f.niri().send_frame_callbacks_to_hidden_windows());

    let window = f.client(id).window(&surface);
    window.set_app_id("relay");
    let frame = window.frame();
    window.commit();
    f.double_roundtrip(id);

    assert!(f.niri().send_frame_callbacks_to_hidden_windows());
    f.double_roundtrip(id);
    assert!(frame.done.load(Ordering::Relaxed));
}
