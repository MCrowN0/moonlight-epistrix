
use godot::{
    classes::{AudioServer, AudioStreamPlayer},
    global::floori,
    prelude::*,
};
use std::cmp::Ordering;

use crate::bpmchange::BpmChange;

/// A tempo change point in time.
///
/// This tracks the time at which the tempo changes, the BPM at that
/// time, and how many beats elapsed before this change.
#[derive(Clone, Copy)]
struct TempoChange {
    time: f64,
    bpm: f64,
    cumulative_beats: f64,
}

/// Internal timing implementation for the conductor.
///
/// This keeps the core beat, tempo, and signal logic separate from the
/// Godot-facing wrapper so the public class stays thin and focused on
/// exposing the node API.
#[derive(Default)]
struct ConductorInternal;

impl ConductorInternal {
    fn ready(conductor: &mut Conductor) {
        conductor.audio_offset = -1.0 * conductor.audio_server.get_output_latency();
    }

    fn process(conductor: &mut Conductor, _delta: f64) {
        if !conductor.active {
            return;
        }

        let last_step: i64 = conductor.step.floor() as i64;
        let last_beat: i64 = conductor.beat.floor() as i64;
        let last_measure: i64 = conductor.measure.floor() as i64;

        if let Some(audio) = &mut conductor.target_audio {
            conductor.raw_time = audio.get_playback_position() as f64
                + conductor.audio_server.get_time_since_last_mix();

            Self::calculate_beat(conductor);

            let current_step: i64 = floori(conductor.step.into());
            let step_range = (last_step + 1)..=current_step;
            let step_count = step_range.end() - step_range.start();
            if step_count <= 100 {
                for step in step_range {
                    conductor.signals().step_hit().emit_tuple((step,));
                }
            }

            let current_beat: i64 = floori(conductor.beat.into());
            let beat_range = (last_beat + 1)..=current_beat;
            let beat_count = beat_range.end() - beat_range.start();
            if beat_count <= 20 {
                for beat in beat_range {
                    conductor.signals().beat_hit().emit_tuple((beat,));
                }
            }

            let current_measure: i64 = floori(conductor.measure.into());
            let measure_range = (last_measure + 1)..=current_measure;
            let measure_count = measure_range.end() - measure_range.start();
            if measure_count <= 10 {
                for measure in measure_range {
                    conductor.signals().measure_hit().emit_tuple((measure,));
                }
            }
        }
    }

    fn get_time(conductor: &Conductor) -> f64 {
        conductor.raw_time + conductor.manual_offset + conductor.audio_offset
    }

    fn get_beat(conductor: &Conductor) -> f64 {
        conductor.beat
    }

    fn get_step(conductor: &Conductor) -> f64 {
        conductor.step
    }

    fn get_measure(conductor: &Conductor) -> f64 {
        conductor.measure
    }

    fn reset_tempo_changes(conductor: &mut Conductor) {
        conductor.tempo_changes = Vec::default();
        conductor.cached_tempo_idx = None;
        conductor.cached_tempo_time = 0.0;
    }

    fn add_tempo_change(conductor: &mut Conductor, change: Gd<BpmChange>) {
        let guard = change.bind();
        let time = guard.time;
        let bpm = guard.bpm;

        let idx = match conductor.tempo_changes.binary_search_by(|c| {
            if c.time < time {
                Ordering::Less
            } else if c.time > time {
                Ordering::Greater
            } else {
                Ordering::Equal
            }
        }) {
            Ok(idx) => idx,
            Err(idx) => idx,
        };

        let cumulative_beats = if idx == 0 {
            time / (60.0 / conductor.tempo)
        } else {
            let prev = &conductor.tempo_changes[idx - 1];
            let segment_duration = time - prev.time;
            prev.cumulative_beats + segment_duration / (60.0 / prev.bpm)
        };

        let new_change = TempoChange {
            time,
            bpm,
            cumulative_beats,
        };

        if idx < conductor.tempo_changes.len()
            && (conductor.tempo_changes[idx].time - time).abs() < f64::EPSILON
        {
            conductor.tempo_changes[idx] = new_change;
        } else {
            conductor.tempo_changes.insert(idx, new_change);
        }

        if idx < conductor.tempo_changes.len() - 1 {
            for i in (idx + 1)..conductor.tempo_changes.len() {
                let prev = &conductor.tempo_changes[i - 1];
                let prev_cum = prev.cumulative_beats;
                let prev_time = prev.time;
                let prev_bpm = prev.bpm;

                let curr = &mut conductor.tempo_changes[i];
                let segment_duration = curr.time - prev_time;
                curr.cumulative_beats = prev_cum + segment_duration / (60.0 / prev_bpm);
            }
        }

        conductor.cached_tempo_idx = None;
    }

    fn tempo_change_index_at_time(conductor: &Conductor, time: f64) -> Option<usize> {
        match conductor.tempo_changes.binary_search_by(|c| {
            if c.time < time {
                Ordering::Less
            } else if c.time > time {
                Ordering::Greater
            } else {
                Ordering::Equal
            }
        }) {
            Ok(idx) => Some(idx),
            Err(0) => None,
            Err(idx) => Some(idx - 1),
        }
    }

    fn tempo_change_index_at_beat(conductor: &Conductor, beat: f64) -> Option<usize> {
        match conductor.tempo_changes.binary_search_by(|c| {
            if c.cumulative_beats < beat {
                Ordering::Less
            } else if c.cumulative_beats > beat {
                Ordering::Greater
            } else {
                Ordering::Equal
            }
        }) {
            Ok(idx) => Some(idx),
            Err(0) => None,
            Err(idx) => Some(idx - 1),
        }
    }

    fn get_tempo_at_time(conductor: &Conductor, time: f64) -> f64 {
        if conductor.tempo_changes.is_empty() {
            return conductor.tempo;
        }

        if let Some(cached_idx) = conductor.cached_tempo_idx {
            if cached_idx < conductor.tempo_changes.len() {
                let cached_change = &conductor.tempo_changes[cached_idx];
                let next_time = if cached_idx + 1 < conductor.tempo_changes.len() {
                    conductor.tempo_changes[cached_idx + 1].time
                } else {
                    f64::INFINITY
                };

                if time >= cached_change.time && time < next_time {
                    return cached_change.bpm;
                }
            }
        }

        if let Some(idx) = Self::tempo_change_index_at_time(conductor, time) {
            conductor.tempo_changes[idx].bpm
        } else {
            conductor.tempo
        }
    }

    fn get_time_from_beat(conductor: &Conductor, target_beat: f64) -> f64 {
        if conductor.tempo_changes.is_empty() {
            return target_beat * (60.0 / conductor.tempo);
        }

        if let Some(first_change) = conductor.tempo_changes.first() {
            if target_beat <= first_change.cumulative_beats {
                return target_beat * (60.0 / conductor.tempo);
            }
        }

        if let Some(idx) = Self::tempo_change_index_at_beat(conductor, target_beat) {
            let change = &conductor.tempo_changes[idx];
            let beat_delta = 60.0 / change.bpm;
            let remaining_beats = target_beat - change.cumulative_beats;
            return change.time + remaining_beats * beat_delta;
        }

        target_beat * (60.0 / conductor.tempo)
    }

    fn get_beat_at_time(conductor: &Conductor, time: f64) -> f64 {
        if conductor.tempo_changes.is_empty() {
            return time / (60.0 / conductor.tempo);
        }

        if let Some(idx) = Self::tempo_change_index_at_time(conductor, time) {
            let change = &conductor.tempo_changes[idx];
            let beat_delta = 60.0 / change.bpm;
            change.cumulative_beats + (time - change.time) / beat_delta
        } else {
            time / (60.0 / conductor.tempo)
        }
    }

    fn calculate_beat(conductor: &mut Conductor) {
        let time = Self::get_time(conductor);
        let current_tempo = Self::get_tempo_at_time(conductor, time);
        if (current_tempo - conductor.cached_tempo).abs() > f64::EPSILON {
            conductor.beat_delta = 60.0 / current_tempo;
            conductor.cached_tempo = current_tempo;
        }
        conductor.beat = Self::get_beat_at_time(conductor, time);
        conductor.step = conductor.beat * 4.0;
        conductor.measure = conductor.beat / 4.0;

        conductor.cached_tempo_time = time;
        if !conductor.tempo_changes.is_empty() {
            conductor.cached_tempo_idx = Self::tempo_change_index_at_time(conductor, time);
        }
    }
}

/// A rhythm timing controller that synchronizes beats, steps,
/// and measures to an `AudioStreamPlayer`.
///
/// Supports tempo changes over time and emits signals when
/// steps, beats, or measures are crossed.
#[derive(GodotClass)]
#[class(base=Node)]
pub struct Conductor {
    #[base]
    base: Base<Node>,

    /// Engine-reported audio output latency offset (negative value).
    /// Applied automatically on `ready()`.
    audio_offset: f64,

    /// Manual timing offset in seconds.
    /// Can be used to fine-tune synchronization.
    #[var]
    manual_offset: f64,

    /// Whether the conductor is actively processing timing.
    #[var]
    active: bool,

    /// Raw playback time (in seconds) from the target audio.
    raw_time: f64,

    /// Current beat position (fractional).
    beat: f64,

    /// Current step position (fractional).
    /// One beat = 4 steps.
    step: f64,

    /// Current measure position (fractional).
    /// One measure = 4 beats.
    measure: f64,

    /// Duration of one beat in seconds (derived from tempo).
    beat_delta: f64,

    /// Cached tempo to avoid recalculating beat_delta unnecessarily
    cached_tempo: f64,

    /// Default tempo in beats per minute.
    #[var]
    tempo: f64,

    /// List of tempo changes sorted by time.
    /// Each entry defines a BPM starting at a specific timestamp.
    tempo_changes: Vec<TempoChange>,

    /// Cached index of the current tempo segment to avoid binary search every frame
    cached_tempo_idx: Option<usize>,
    cached_tempo_time: f64,

    audio_server: Gd<AudioServer>,

    /// The audio source this conductor tracks.
    #[var]
    target_audio: Option<Gd<AudioStreamPlayer>>,
}

#[godot_api]
impl INode for Conductor {
    /// Initializes the conductor with default values.
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            audio_offset: 0.0,
            manual_offset: 0.0,
            active: false,
            raw_time: 0.0,
            beat: 0.0,
            step: 0.0,
            measure: 0.0,
            beat_delta: 0.0,
            tempo: 130.0,
            cached_tempo: 130.0,
            audio_server: AudioServer::singleton(),
            tempo_changes: Vec::default(),
            cached_tempo_idx: None,
            cached_tempo_time: 0.0,
            target_audio: None,
        }
    }

    /// Called when the node enters the scene tree.
    ///
    /// Calculates audio output latency and stores it as an offset.
    fn ready(&mut self) {
        ConductorInternal::ready(self);
    }

    /// Called every frame.
    ///
    /// Updates timing based on the target audio playback position
    /// and emits step/beat/measure signals when boundaries are crossed.
    fn process(&mut self, _delta: f64) {
        ConductorInternal::process(self, _delta);
    }
}

#[godot_api]
impl Conductor {
    /// Returns the corrected playback time in seconds,
    /// including manual and audio latency offsets.
    #[func]
    pub fn get_time(&self) -> f64 {
        ConductorInternal::get_time(self)
    }

    /// Returns the current fractional beat.
    #[func]
    fn get_beat(&self) -> f64 {
        ConductorInternal::get_beat(self)
    }

    /// Returns the current fractional step.
    ///
    /// 1 beat = 4 steps.
    #[func]
    fn get_step(&self) -> f64 {
        ConductorInternal::get_step(self)
    }

    /// Returns the current fractional measure.
    ///
    /// 1 measure = 4 beats.
    #[func]
    fn get_measure(&self) -> f64 {
        ConductorInternal::get_measure(self)
    }

    /// Clears all registered tempo changes.
    #[func]
    fn reset_tempo_changes(&mut self) {
        ConductorInternal::reset_tempo_changes(self);
    }

    /// Adds a new tempo change.
    ///
    /// The change should define a time (in seconds)
    /// and the BPM starting at that time. The list is kept sorted
    /// and cumulative beat counts are updated for fast lookups.
    #[func]
    fn add_tempo_change(&mut self, change: Gd<BpmChange>) {
        ConductorInternal::add_tempo_change(self, change);
    }

    /// Returns the index of the last tempo change that occurs at or before `time`.
    ///
    /// Returns `None` if `time` is before the first tempo change.
    #[inline]
    fn tempo_change_index_at_time(&self, time: f64) -> Option<usize> {
        ConductorInternal::tempo_change_index_at_time(self, time)
    }

    /// Returns the index of the last tempo change that occurs at or before `beat`.
    ///
    /// Returns `None` if `beat` is before the first tempo change.
    #[inline]
    fn tempo_change_index_at_beat(&self, beat: f64) -> Option<usize> {
        ConductorInternal::tempo_change_index_at_beat(self, beat)
    }

    /// Returns the tempo (BPM) active at a specific time.
    /// Uses cached tempo segment for better performance.
    #[func]
    fn get_tempo_at_time(&self, time: f64) -> f64 {
        ConductorInternal::get_tempo_at_time(self, time)
    }

    /// Converts a beat position into a time value (in seconds),
    /// accounting for tempo changes.
    #[func]
    fn get_time_from_beat(&self, target_beat: f64) -> f64 {
        ConductorInternal::get_time_from_beat(self, target_beat)
    }

    /// Returns the exact fractional beat at a specific time (seconds),
    /// fully accounting for tempo changes.
    #[func]
    fn get_beat_at_time(&self, time: f64) -> f64 {
        ConductorInternal::get_beat_at_time(self, time)
    }

    /// Calculates the current beat, step, and measure
    /// based on playback time and tempo changes.
    fn calculate_beat(&mut self) {
        ConductorInternal::calculate_beat(self);
    }

    /// Emitted whenever a new step is crossed.
    #[signal]
    pub fn step_hit(step: i64);

    /// Emitted whenever a new beat is crossed.
    #[signal]
    pub fn beat_hit(step: i64);

    /// Emitted whenever a new measure is crossed.
    #[signal]
    pub fn measure_hit(measure: i64);
}
