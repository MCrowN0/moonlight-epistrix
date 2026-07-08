use godot::classes::image::Format;
use godot::classes::{FileAccess, Image, ImageTexture};
use godot::prelude::*;
use zenavif::decode;
/// # THE COOLEST CLASS OF ALL TIME
/// # FROM PROJECT: OVERKILL
/// # THIS IS SUCH A COOL CLASS AND IF YOU DISAGREE GO FUCK YOURSELF'
#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct CoolUtil;

#[godot_api]
pub impl CoolUtil {
    #[func]
    pub fn get_note_visible_time(
        target_time_ms: f64,
        scroll_speed: f32,
        strum_y: f64,
        visible_y: f64,
    ) -> f64 {
        (target_time_ms + 1.0 - 2.0 * (visible_y - strum_y) / scroll_speed as f64) / 1000.0
    }

    #[func]
    pub fn should_note_be_visible(
        current_time: f64,
        target_time_ms: f64,
        scroll_speed: f32,
        strum_y: f64,
        visible_y: f64,
    ) -> bool {
        let note_visible_time =
            Self::get_note_visible_time(target_time_ms, scroll_speed, strum_y, visible_y);
        current_time >= note_visible_time
    }

    #[func]
    pub fn load_avif(path: String) -> Gd<ImageTexture> {
        let file_bytes = FileAccess::get_file_as_bytes(&path);
        let pixel_buffer = decode(file_bytes.as_slice()).expect("Failed to decode AVIF");
        let width = pixel_buffer.width() as i32;
        let height = pixel_buffer.height() as i32;
        let bytes = pixel_buffer.copy_to_contiguous_bytes();

        let mut rgba_data = Vec::with_capacity((width as usize) * (height as usize) * 4);
        for chunk in bytes.chunks(3) {
            if chunk.len() == 3 {
                rgba_data.push(chunk[0]);
                rgba_data.push(chunk[1]);
                rgba_data.push(chunk[2]);
                rgba_data.push(0xFF);
            }
        }

        let data = PackedByteArray::from(rgba_data.as_slice());
        let image = Image::create_from_data(width, height, false, Format::RGBA8, &data)
            .expect("Failed to create image");

        ImageTexture::create_from_image(&image).expect("Failed to create texture")
    }

    /*
    */

    /// Linearly interpolates between `a` and `b` by the factor `t`.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor (0.0 returns `a`, 1.0 returns `b`).
    ///
    /// # Returns
    /// A value between `a` and `b` linearly interpolated by `t`.
    #[func]
    pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
        a + (b - a) * t
    }

    /// Smoothly interpolates between `a` and `b` using a cubic Hermite curve.
    /// Clamps `t` between 0.0 and 1.0 for smooth start and end transitions.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor (clamped between 0.0 and 1.0).
    ///
    /// # Returns
    /// A value between `a` and `b` with eased acceleration and deceleration.
    #[func]
    pub fn smoothstep(a: f32, b: f32, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        let t = t * t * (3.0 - 2.0 * t);
        a + (b - a) * t
    }

    /// Smoothly interpolates between `a` and `b` with a quintic Hermite curve.
    /// Provides even smoother acceleration and deceleration than `smoothstep`.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor (clamped between 0.0 and 1.0).
    ///
    /// # Returns
    /// A value between `a` and `b` with very smooth start and end transitions.
    #[func]
    pub fn smootherstep(a: f32, b: f32, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        let t = t * t * t * (t * (6.0 * t - 15.0) + 10.0);
        a + (b - a) * t
    }

    /// Interpolates between `a` and `b` in a ping-pong fashion.
    /// `t` loops between 0 and 2, first moving from `a` to `b`, then back from `b` to `a`.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor, repeating every 2.0 units.
    ///
    /// # Returns
    /// A value that oscillates between `a` and `b`.
    #[func]
    pub fn ping_pong(a: f32, b: f32, t: f32) -> f32 {
        let t = t % 2.0;
        if t < 1.0 {
            Self::lerp(a, b, t)
        } else {
            Self::lerp(b, a, t - 1.0)
        }
    }

    /// Interpolates between `a` and `b` with an elastic effect, overshooting before settling.
    /// Clamps `t` between 0.0 and 1.0.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor (clamped between 0.0 and 1.0).
    ///
    /// # Returns
    /// A value that starts slowly, overshoots, and then settles at `b`.
    #[func]
    pub fn elastic_lerp(a: f32, b: f32, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        let p = 0.3;
        let s = p / 4.0;
        if t == 0.0 {
            return a;
        }
        if t == 1.0 {
            return b;
        }
        let t = t - 1.0;
        a + (b - a)
            * (-(2.0_f32).powf(10.0 * t) * ((t - s) * (2.0 * std::f32::consts::PI) / p).sin() + 1.0)
    }

    /// Interpolates between `a` and `b` following a circular easing curve.
    /// Clamps `t` between 0.0 and 1.0 for smooth acceleration.
    ///
    /// # Arguments
    /// * `a` - The start value.
    /// * `b` - The end value.
    /// * `t` - Interpolation factor (clamped between 0.0 and 1.0).
    ///
    /// # Returns
    /// A value that accelerates according to a circular curve.
    #[func]
    pub fn circ_lerp(a: f32, b: f32, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        a + (b - a) * (1.0 - (1.0 - t * t).sqrt())
    }

    /// Generates a pseudo-random value between 0 and 1 based on input `x`.
    /// Useful for procedural randomness with smooth transitions.
    ///
    /// # Arguments
    /// * `x` - Input value.
    ///
    /// # Returns
    /// A pseudo-random value between 0.0 and 1.0.
    #[func]
    pub fn smooth_random(x: f32) -> f32 {
        ((x.sin() * 12.9898).sin() * 43758.5453) % 1.0
    }

    /// Generates a triangular "ping" wave between 0 and 0.5.
    /// Repeats every 1.0 unit of `x`.
    ///
    /// # Arguments
    /// * `x` - Input value.
    ///
    /// # Returns
    /// A value oscillating from 0.0 up to 0.5 and back to 0.0 in a triangular wave.
    #[func]
    pub fn ping_wave(x: f32) -> f32 {
        (x % 1.0).min(1.0 - (x % 1.0))
    }
}
