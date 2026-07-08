use godot::prelude::*;

use crate::inputtracker::{HitStamp, HoldStamp};

/// Judgment engine that evaluates note timing and holds a timing offset.
pub struct InputJudge {
    early_sick_window: u8,
    early_good_window: u8,
    early_bad_window: u8,
    early_shit_window: u8,
    
    late_sick_window: u8,
    late_good_window: u8,
    late_bad_window: u8,
    late_shit_window: u8,
}

struct RatingWindow {
    early: u8,
    late: u8,
    rating: Rating,
}

impl InputJudge {
    /// Creates a new judge with default timing windows and offset tracking.
    pub fn new() -> Self {
        Self {
            early_sick_window: 50,
            early_good_window: 70,
            early_bad_window: 90,
            early_shit_window: 100,
            
            late_sick_window: 30,
            late_good_window: 50,
            late_bad_window: 70,
            late_shit_window: 80
        }
    }

    fn get_rating_for_delta(&self, delta: f32) -> Option<Rating> {
        let windows = [
            RatingWindow { early: self.early_sick_window, late: self.late_sick_window, rating: Rating::Sick },
            RatingWindow { early: self.early_good_window, late: self.late_good_window, rating: Rating::Good },
            RatingWindow { early: self.early_bad_window, late: self.late_bad_window, rating: Rating::Bad },
            RatingWindow { early: self.early_shit_window, late: self.late_shit_window, rating: Rating::Shit },
        ];

        for window in &windows {
            let early_bound = -(window.early as f32);
            let late_bound = window.late as f32;
            if delta >= early_bound && delta <= late_bound {
                return Some(window.rating.clone());
            }
        }

        if delta >= -(self.early_shit_window as f32) && delta <= self.late_shit_window as f32 {
            Some(Rating::Miss)
        } else {
            None
        }
    }

    pub fn check_note_hit(
        &mut self,
        song_time_ms: f64,
        target_time_ms: f64,
        note_length_ms: f64,
        hit_stamp: HitStamp,
        hold_stamp: HoldStamp,

        is_cpu: bool,
    ) -> JudgeResult {
        let mut result = JudgeResult {
            rating: None,
            hit: false,
            accuracy: 0.0,
            start_hold: false
        };

        if is_cpu {
            if song_time_ms >= target_time_ms {
                result.rating = Some(Rating::Sick);
                result.hit = true;
                result.accuracy = 0.0;
                result.start_hold = note_length_ms > 0.0;
                return result;
            }
            result.hit = false;
            return result;
        }

        let difference: f64 = hit_stamp.timestamp - target_time_ms;
        if difference.abs() < 90.0 && hit_stamp.valid {
            result.rating = self.get_rating_for_delta(difference as f32);
            result.hit = true;
            result.accuracy = 0.0;
            result.start_hold = true;
            return result;
        }

        if let Some(note_time) = hit_stamp.associated_note_time {
            if !hit_stamp.valid {
                if hold_stamp.start_timestamp != hit_stamp.timestamp {
                    if note_time == target_time_ms {
                        result.hit = true;
                        result.start_hold = true;
                        return result;
                    }
                }
            }
        }

        result.hit = false;
        result
    }
}

const RATINGS: [&str; 5] = ["miss", "shit", "bad", "good", "sick"];

/// Judgment classification for note timing.
#[derive(Clone, Copy)]
pub enum Rating {
    Miss,
    Shit,
    Bad,
    Good,
    Sick
}

/// Result of a note judgment, including rating, hit state, and accuracy.
pub struct JudgeResult {
    rating: Option<Rating>,
    pub hit: bool,
    accuracy: f32,
    start_hold: bool
}

impl JudgeResult {
    /// Converts the judgment result into a Godot-friendly dictionary.
    pub fn to_dictionary(&self) -> VarDictionary {
        let mut dict = VarDictionary::new();
        if let Some(rating) = self.rating {
            dict.set("rating", RATINGS[rating as usize]);
        }
        else {
            dict.set("rating", "none");
        }
        dict.set("hit", self.hit);
        dict.set("accuracy", self.accuracy);
        dict.set("start_hold", self.start_hold);
        dict
    }
}
