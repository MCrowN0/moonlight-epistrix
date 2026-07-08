use std::{collections::HashMap, io::{Read, Write}};

use godot::{classes::FileAccess, prelude::*};
use serde::{Deserialize, Serialize};
use zstd::stream::{Decoder, Encoder};

#[derive(Serialize, Deserialize, Default, Clone)]
pub struct CharacterHeader {
    pub version: u16,
}

#[derive(Serialize, Deserialize, Default, Clone)]
pub struct CharacterMetadata {
    pub path: String,
    pub default_animation: String,
    pub format: String
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Animation {
    pub animation: String,
    pub prefix: String,
    pub framerate: u8,
    pub looped: bool,
    pub offset: (f32, f32)
}

#[derive(Serialize, Deserialize, Default, Clone)]
pub struct CharacterData {
    pub header: CharacterHeader,
    pub metadata: CharacterMetadata,
    pub animations: Vec<Animation>,
}

#[derive(Serialize, Deserialize)]
struct CompactCharacterMetadata {
    path: u16,
    default_animation: u16,
    format: u16,
}

#[derive(Serialize, Deserialize)]
struct CompactAnimation {
    animation: u16,
    prefix: u16,
    framerate: u8,
    looped: bool,
    offset: (f32, f32),
}

#[derive(Serialize, Deserialize)]
struct CompactCharacterData {
    header: CharacterHeader,
    metadata: CompactCharacterMetadata,
    animations: Vec<CompactAnimation>,
    strings: Vec<String>,
}

impl CompactCharacterData {
    fn to_character_data(self) -> CharacterData {
        let strings = self.strings;

        CharacterData {
            header: self.header,
            metadata: CharacterMetadata {
                path: strings[self.metadata.path as usize].clone(),
                default_animation: strings[self.metadata.default_animation as usize].clone(),
                format: strings[self.metadata.format as usize].clone(),
            },
            animations: self
                .animations
                .into_iter()
                .map(|animation| Animation {
                    animation: strings[animation.animation as usize].clone(),
                    prefix: strings[animation.prefix as usize].clone(),
                    framerate: animation.framerate,
                    looped: animation.looped,
                    offset: animation.offset,
                })
                .collect(),
        }
    }
}

fn add_string(strings: &mut Vec<String>, index_map: &mut HashMap<String, u16>, value: &str) -> u16 {
    if let Some(&index) = index_map.get(value) {
        return index;
    }

    let index = u16::try_from(strings.len()).unwrap_or(u16::MAX);
    strings.push(value.to_string());
    index_map.insert(value.to_string(), index);
    index
}

fn compact_character_payload(character: &CharacterData) -> Result<Vec<u8>, postcard::Error> {
    let mut strings = Vec::new();
    let mut index_map = HashMap::new();

    let metadata = CompactCharacterMetadata {
        path: add_string(&mut strings, &mut index_map, &character.metadata.path),
        default_animation: add_string(&mut strings, &mut index_map, &character.metadata.default_animation),
        format: add_string(&mut strings, &mut index_map, &character.metadata.format),
    };

    let animations = character
        .animations
        .iter()
        .map(|animation| CompactAnimation {
            animation: add_string(&mut strings, &mut index_map, &animation.animation),
            prefix: add_string(&mut strings, &mut index_map, &animation.prefix),
            framerate: animation.framerate,
            looped: animation.looped,
            offset: animation.offset,
        })
        .collect();

    let compact = CompactCharacterData {
        header: character.header.clone(),
        metadata,
        animations,
        strings,
    };

    postcard::to_allocvec(&compact)
}

#[derive(GodotClass)]
#[class(init, base=Resource)]
pub struct CharacterResource {
    character: CharacterData
}


#[godot_api]
impl CharacterResource {
    #[func]
    pub fn new_empty(&mut self, path: String, default_animation: String, format: String) {
        self.character = CharacterData {
            header: CharacterHeader { version: 1 },
            metadata: CharacterMetadata {
                path,
                default_animation,
                format,
            },
            animations: Vec::new(),
        };
    }

    #[func]
    pub fn add_animation(&mut self, animation: String, prefix: String, framerate: u8, looped: bool, offset: Vector2) {
        let offset_rs: (f32, f32) = (offset.x, offset.y);
        self.character.animations.push(Animation {
            animation,
            prefix,
            framerate,
            looped,
            offset: offset_rs
        });
    }

    #[func]
    pub fn get_metadata(&self) -> Variant {
        let mut metadata = VarDictionary::new();
        let _ = metadata.insert("path", self.character.metadata.path.clone());
        let _ = metadata.insert("default_animation", self.character.metadata.default_animation.clone());
        let _ = metadata.insert("format", self.character.metadata.format.clone());
        metadata.to_variant()
    }

    fn animation_to_dict(animation: &Animation) -> VarDictionary {
        let mut dict = VarDictionary::new();
        let _ = dict.insert("animation", animation.animation.clone());
        let _ = dict.insert("prefix", animation.prefix.clone());
        let _ = dict.insert("framerate", animation.framerate);
        let _ = dict.insert("looped", animation.looped);

        let offset_god: Vector2 = Vector2 {
            x: animation.offset.0,
            y: animation.offset.1
        };

        let _ = dict.insert("offset", offset_god);

        dict
    }

    #[func]
    pub fn get_animations(&self) -> Array<Variant> {
        self.character
            .animations
            .iter()
            .map(|animation| Self::animation_to_dict(animation).to_variant())
            .collect()
    }

    #[func]
    pub fn save(&self, path: String) -> bool {
        let Ok(bytes) = compact_character_payload(&self.character) else {
            return false;
        };
        let Ok(mut encoder) = Encoder::new(Vec::new(), 22) else {
            return false;
        };
        if encoder.write_all(&bytes).is_err() {
            return false;
        }
        let Ok(compressed) = encoder.finish() else {
            return false;
        };
        std::fs::write(path, compressed).is_ok()
    }

    #[func]
    pub fn load(&mut self, path: String) -> bool {
        let file = FileAccess::get_file_as_bytes(&path);
        let Ok(mut decoder) = Decoder::new(file.as_slice()) else {
            return false;
        };
        let mut decompressed = Vec::new();
        if decoder.read_to_end(&mut decompressed).is_err() {
            return false;
        }
        if let Ok(compact) = postcard::from_bytes::<CompactCharacterData>(decompressed.as_slice()) {
            self.character = compact.to_character_data();
            return true;
        }

        postcard::from_bytes::<CharacterData>(decompressed.as_slice())
            .map(|character| {
                self.character = character;
                true
            })
            .unwrap_or(false)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compact_payload_is_smaller_for_repeated_strings() {
        let character = CharacterData {
            header: CharacterHeader { version: 1 },
            metadata: CharacterMetadata {
                path: "chars/demo".into(),
                default_animation: "idle".into(),
                format: "png".into(),
            },
            animations: vec![
                Animation {
                    animation: "idle".into(),
                    prefix: "idle".into(),
                    framerate: 12,
                    looped: true,
                    offset: (0.0, 0.0),
                },
                Animation {
                    animation: "walk".into(),
                    prefix: "walk".into(),
                    framerate: 12,
                    looped: true,
                    offset: (1.5, -2.0),
                },
            ],
        };

        let old_bytes = postcard::to_allocvec(&character).unwrap();
        let new_bytes = compact_character_payload(&character).unwrap();

        assert!(new_bytes.len() < old_bytes.len());
    }
}

