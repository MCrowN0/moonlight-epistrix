use godot::{
    builtin::{StringName, Vector2},
    classes::{AnimatedSprite2D, IAnimatedSprite2D},
    prelude::*,
    register::{GodotClass, godot_api},
};
use std::collections::HashMap;

/// Custom AnimatedSprite2D with per-animation offsets.
/// Recommended way to handle animation-specific sprite positioning in Project: Overkill.
#[derive(GodotClass)]
#[class(base = AnimatedSprite2D)]
struct OffsetAnimatedSprite2D {
    offsets: HashMap<StringName, Vector2>,
    last_animation: StringName,

    #[base]
    base: Base<AnimatedSprite2D>,
}

#[godot_api]
impl IAnimatedSprite2D for OffsetAnimatedSprite2D {
    fn init(base: Base<AnimatedSprite2D>) -> Self {
        Self {
            offsets: HashMap::new(),
            last_animation: StringName::default(),
            base,
        }
    }

    fn process(&mut self, _delta: f64) {
        let current = {
            let base_imm = self.base();
            base_imm.get_animation()
        };

        // if current == self.last_animation {
        //     return;
        // }

        self.last_animation = current.clone();

        let offset = self.offsets.get(&current).copied();

        let mut sprite = self.base_mut();
        if let Some(offset_val) = offset {
            //let scale = sprite.get_scale();
            //let scaled_offset = Vector2 {
            //    x: offset_val.x * scale.x,
            //    y: offset_val.y * scale.y,
            //};
            sprite.set_offset(offset_val);
        } else {
            sprite.set_offset(Vector2::ZERO);
        }
    }
}

#[godot_api]
impl OffsetAnimatedSprite2D {
    /// Registers an offset for the given animation name.
    #[func]
    fn add_offset(&mut self, animation: StringName, offset: Vector2) {
        self.offsets.insert(animation, offset);
    }

    /// Removes all registered animation offsets.
    #[func]
    fn clear_offsets(&mut self) {
        self.offsets.clear();
    }

    /// Removes the offset associated with the specified animation.
    #[func]
    fn remove_offset(&mut self, animation: StringName) {
        self.offsets.remove(&animation);
    }

    #[func]
    fn update_offset(&mut self, animation: StringName, new_offset: Vector2) {
        self.remove_offset(animation.clone());
        self.add_offset(animation.clone(), new_offset);
    }

    /// Returns the offset for the specified animation, or zero if unset.
    #[func]
    fn get_offset(&self, animation: StringName) -> Vector2 {
        self.offsets
            .get(&animation)
            .copied()
            .unwrap_or(Vector2::ZERO)
    }
}
