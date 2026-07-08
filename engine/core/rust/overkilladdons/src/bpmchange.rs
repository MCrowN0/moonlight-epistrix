use godot::prelude::*;

use crate::eventdata::IEvent;

/// A scheduled BPM change attached to a song timeline.
///
/// This resource stores the time and BPM value for a tempo change.
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct BpmChange {
    #[base]
    base: Base<Resource>,

    #[export]
    pub time: f64,

    #[export]
    pub bpm: f64,
}

impl IEvent for BpmChange {
    fn name(&self) -> GString {
        "BPM Change".into()
    }

    fn time(&self) -> f64 {
        self.time
    }

    fn set_time(&mut self, time: f64) {
        self.time = time;
    }
}
