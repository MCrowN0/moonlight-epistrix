use std::io::{Read, Write};

use godot::{classes::FileAccess, prelude::GodotClass};
use godot::prelude::*;
use zstd::stream::{Encoder, Decoder};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Default)]
/// Header metadata for a saved chart file.
pub struct ChartHeader {
    pub version: u16,
}

#[derive(Serialize, Deserialize, Default)]
/// Global chart settings such as base tempo and scroll speed.
pub struct ChartMetadata {
    pub base_bpm: f32,
    pub scroll_speed: f32
}

#[derive(Serialize, Deserialize)]
/// A note entry in a song chart.
pub struct Note {
    pub time: f32,
    pub id: u8,
    pub length: f32
}

#[derive(Serialize, Deserialize)]
/// A section within a song chart containing notes and BPM info.
pub struct Section {
    pub beats: f32,
    pub notes: Vec<Note>,
    pub must_hit_section: bool,
    pub change_bpm: bool,
    pub bpm: f32
}

#[derive(Serialize, Deserialize, Default)]
/// Complete song chart data including sections, tempo, and metadata.
pub struct SongChart {
    pub header: ChartHeader,
    pub metadata: ChartMetadata,
    pub sections: Vec<Section>
}

#[derive(GodotClass)]
/// Godot resource wrapper for song chart serialization and inspection.
#[class(init, base=Resource)]
pub struct ChartResource {
    chart: SongChart
}


#[godot_api]
impl ChartResource {
    /// Initializes an empty chart with the provided tempo and scroll speed.
    #[func]
    pub fn new_empty(&mut self, bpm: f32, scroll_speed: f32, section_amount: i64) {
        self.chart = SongChart {
            header: ChartHeader { version: 1 },
            metadata: ChartMetadata {
                base_bpm: bpm,
                scroll_speed: scroll_speed,
            },
            sections: Vec::with_capacity(section_amount as usize),
        };
    }

    #[func]
    /// Appends a new section to the chart with the specified length and BPM options.
    pub fn add_section(&mut self, beats: f32, must_hit_section: bool, change_bpm: bool, bpm: f32, note_amount: i64) {
        self.chart.sections.push(Section {
            beats,
            notes: Vec::with_capacity(note_amount as usize),
            must_hit_section: must_hit_section,
            change_bpm: change_bpm,
            bpm: bpm,
        });
    }

    #[func]
    /// Adds a note to the specified section.
    pub fn add_note(&mut self, section_index: i32, time: f32, id: u8, length: f32) {
        let section = self.chart.sections.get_mut(section_index as usize).unwrap();
        section.notes.push(Note {
            time,
            id,
            length,
        });
    }

    #[func]
    /// Returns chart metadata as a dictionary containing BPM and scroll speed.
    pub fn get_metadata(&self) -> Variant {
        let mut metadata = VarDictionary::new();
        let _ = metadata.insert("bpm", self.chart.metadata.base_bpm);
        let _ = metadata.insert("scroll_speed", self.chart.metadata.scroll_speed);
        metadata.to_variant()
    }

    fn note_to_dict(note: &Note) -> VarDictionary {
        let mut dict = VarDictionary::new();
        let _ = dict.insert("time", note.time as f64);
        let _ = dict.insert("id", note.id as i64);
        let _ = dict.insert("length", note.length as f64);
        dict
    }

    fn section_to_dict(section: &Section) -> VarDictionary {
        let mut dict = VarDictionary::new();
        let _ = dict.insert("beats", section.beats as f64);
        let _ = dict.insert("must_hit_section", section.must_hit_section);
        let _ = dict.insert("change_bpm", section.change_bpm);
        let _ = dict.insert("bpm", section.bpm as f64);

        let notes_array: Array<Variant> = section
            .notes
            .iter()
            .map(|note| Self::note_to_dict(note).to_variant())
            .collect();

        let _ = dict.insert("notes", notes_array);
        dict
    }

    #[func]
    /// Returns all chart sections as an array of dictionaries.
    pub fn get_sections(&self) -> Array<Variant> {
        self.chart
            .sections
            .iter()
            .map(|section| Self::section_to_dict(section).to_variant())
            .collect()
    }

    #[func]
    /// Serializes and compresses the chart to the given file path.
    pub fn save(&self, path: String) -> bool {
        match postcard::to_allocvec(&self.chart) {
            Ok(bytes) => {
                match Encoder::new(Vec::new(), 22) {
                    Ok(mut e) => {
                        if let Ok(()) = e.write_all(bytes.as_slice()) {
                            if let Ok(compressed) = e.finish() {
                                return std::fs::write(path, compressed).is_ok();
                            }
                        }
                    }
                    Err(_) => {}
                }
            }
            Err(_) => {}
        }
        false
    }

    #[func]
    /// Loads chart data from a compressed file previously written by `save`.
    pub fn load(&mut self, path: String) -> bool {
        let file = FileAccess::get_file_as_bytes(&path);
        let slice: &[u8] = file.as_slice();
        match Decoder::new(slice) {
            Ok(mut d) => {
                let mut decompressed = Vec::new();
                if let Ok(_) = d.read_to_end(&mut decompressed) {
                    match postcard::from_bytes::<SongChart>(decompressed.as_slice()) {
                        Ok(chart) => {
                            self.chart = chart;
                            return true;
                        }
                        Err(_) => {}
                    }
                }
            }
            Err(_) => {}
        }
        false
    }
}

