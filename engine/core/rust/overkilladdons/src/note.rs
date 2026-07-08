use godot::{
    classes::{AnimatedSprite2D, IAnimatedSprite2D}, prelude::*, register::{GodotClass, godot_api}
};

#[derive(GodotClass)]
/// Godot sprite class used to represent a note object in the rhythm game.
#[class(base = AnimatedSprite2D)]
struct Note {
    #[base]
    base: Base<AnimatedSprite2D>
}

#[godot_api]
impl IAnimatedSprite2D for Note {
    fn init(base: Base<AnimatedSprite2D>) -> Self {
        Self {
            base,
        }
    }
}
