use godot::classes::{Input, InputEvent, InputEventKey};
use godot::global::{Key};
use godot::prelude::*;
use crate::conductor::Conductor;

use crate::inputjudge::InputJudge;

#[derive(Clone)]
struct Keybinds {
    binds: [[Key; 2]; 4],
}

#[derive(Clone, Copy)]
pub struct HitStamp {
    pub timestamp: f64,
    pub associated_note_time: Option<f64>,
    pub valid: bool
}

#[derive(Clone, Copy)]
pub struct HoldStamp { 
    pub start_timestamp: f64,
    pub end_timestamp: f64,
    pub valid: bool
}

#[derive(GodotClass)]
/// Godot node that tracks keyboard input and exposes judgment helpers.
#[class(base=Node)]
struct InputTracker {
    #[base]
    base: Base<Node>,
    keybinds: Keybinds,
    hit_stamps: [HitStamp; 4],
    hold_stamps: [HoldStamp; 4],
    judge: InputJudge,
    hitting_lane: [bool; 4],
    secondary_enabled: bool,

    #[var]
    conductor: Option<Gd<Conductor>>,

    #[var]
    is_cpu_strum: bool
}

#[godot_api]
impl INode for InputTracker {
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            keybinds: Keybinds {
                binds: [
                    [Key::A, Key::LEFT],
                    [Key::S, Key::DOWN],
                    [Key::W, Key::UP],
                    [Key::D, Key::RIGHT],
                ],
            },
            judge: InputJudge::new(),
            hitting_lane: [false, false, false, false],
            hit_stamps: [HitStamp { timestamp: 0.0, associated_note_time: None, valid: true }, HitStamp { timestamp: 0.0, associated_note_time: None, valid: true }, HitStamp { timestamp: 0.0, associated_note_time: None, valid: true }, HitStamp { timestamp: 0.0, associated_note_time: None, valid: true }],
            hold_stamps: [HoldStamp { start_timestamp: 0.0, end_timestamp: 0.0, valid: true }, HoldStamp { start_timestamp: 0.0, end_timestamp: 0.0, valid: true }, HoldStamp { start_timestamp: 0.0, end_timestamp: 0.0, valid: true }, HoldStamp { start_timestamp: 0.0, end_timestamp: 0.0, valid: true }],
            conductor: None,
            secondary_enabled: true,
            is_cpu_strum: false,
        }
    }

    fn input(&mut self, event: Gd<InputEvent>) {
        if event.get_class() != "InputEventKey" || self.is_cpu_strum {
            return;
        }

        let key_event = event.cast::<InputEventKey>();

        let note_id: u8 = self.key_to_id(key_event.get_keycode());
        if note_id == 255 {
            return;
        }

        if key_event.is_pressed() && !self.hitting_lane[note_id as usize] {
            self.hitting_lane[note_id as usize] = true;

            if let Some(conductor) = &self.conductor {
                self.hit_stamps[note_id as usize] = HitStamp { timestamp: conductor.bind().get_time() * 1000.0, associated_note_time: None, valid: true};
            }
        }
        if key_event.is_released() {
            self.hitting_lane[note_id as usize] = false;
            let start_timestamp: f64 = self.hit_stamps[note_id as usize].timestamp;

            if let Some(conductor) = &self.conductor {
                let end_timestamp = conductor.bind().get_time() * 1000.0;
                self.hold_stamps[note_id as usize] = HoldStamp { start_timestamp, end_timestamp, valid: true};
            }
        }
    }
}

#[godot_api]
impl InputTracker {
    fn key_to_id(&self, key: Key) -> u8 {
        if key == self.keybinds.binds[0][0] || (key == self.keybinds.binds[0][1] && self.secondary_enabled) {
            return 0;
        }
        else if key == self.keybinds.binds[1][0] || (key == self.keybinds.binds[1][1] && self.secondary_enabled) {
            return 1;
        }
        else if key == self.keybinds.binds[2][0] || (key == self.keybinds.binds[2][1] && self.secondary_enabled) {
            return 2;
        }
        else if key == self.keybinds.binds[3][0] || (key == self.keybinds.binds[3][1] && self.secondary_enabled) {
            return 3;
        }
        255
    }

    #[func]
    /// Checks a note hit using current input state and returns a Godot dictionary result.
    pub fn check_note_hit(
        &mut self,
        song_time_ms: f64,
        target_time_ms: f64,
        note_length_ms: f64,
        note_id: u8,
        is_cpu: bool,
    ) -> VarDictionary {
        let judgement = self.judge.check_note_hit(
            song_time_ms,
            target_time_ms,
            note_length_ms,
            self.hit_stamps[note_id as usize],
            self.hold_stamps[note_id as usize],
            is_cpu
        );
        if judgement.hit {
            self.hit_stamps[note_id as usize].valid = false;
            self.hit_stamps[note_id as usize].associated_note_time = Some(target_time_ms);
        }
        judgement.to_dictionary()
    }

    #[func]
    pub fn get_pressed(&self, id: u8) -> bool {
        Input::singleton().is_key_pressed(self.keybinds.binds[id as usize][0]) || Input::singleton().is_key_pressed(self.keybinds.binds[id as usize][1])
    }

    #[inline(always)]
    fn set_keybind(&mut self, direction: usize, variant: usize, godot_key: godot::global::Key) {
        self.keybinds.binds[direction][variant] = godot_key;
    }

    #[func]
    fn set_left_primary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(0, 0, godot_key);
    }

    #[func]
    fn set_left_secondary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(0, 1, godot_key);
    }

    #[func]
    fn set_down_primary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(1, 0, godot_key);
    }

    #[func]
    fn set_down_secondary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(1, 1, godot_key);
    }

    #[func]
    fn set_up_primary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(2, 0, godot_key);
    }

    #[func]
    fn set_up_secondary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(2, 1, godot_key);
    }

    #[func]
    fn set_right_primary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(3, 0, godot_key);
    }

    #[func]
    fn set_right_secondary(&mut self, godot_key: godot::global::Key) {
        self.set_keybind(3, 1, godot_key);
    }

    #[func]
    fn set_secondary_enabled(&mut self, enabled: bool) {
        self.secondary_enabled = enabled;
    }
}