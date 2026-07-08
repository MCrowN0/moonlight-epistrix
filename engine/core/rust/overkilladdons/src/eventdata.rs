use godot::prelude::*;

/// A Godot resource representing a named event with payload data and timing.
#[derive(GodotClass)]
#[class(base=Resource)]
pub struct EventData {
    #[base]
    base: Base<Resource>,

    #[export]
    name: GString,

    #[export]
    data: Array<Variant>,

    #[export]
    time: f32,
}

#[godot_api]
impl IResource for EventData {
    fn init(base: Base<Resource>) -> Self {
        Self {
            base,
            name: "Event".into(),
            data: Array::new(),
            time: 0.0,
        }
    }
}

/// Trait for timeline events that expose a display name and time.
pub trait IEvent {
    fn name(&self) -> GString;
    fn time(&self) -> f64;
    fn set_time(&mut self, time: f64);
}
