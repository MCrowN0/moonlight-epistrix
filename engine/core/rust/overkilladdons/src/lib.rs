//! Godot extension library for Project: Overkill core utilities.

use godot::prelude::*;

struct OverkillExtension;

#[gdextension]
unsafe impl ExtensionLibrary for OverkillExtension {}

pub mod bpmchange;
pub mod conductor;
pub mod constants;
pub mod coolutil;
pub mod eventdata;
pub mod chartresource;
pub mod characterresource;
mod eventnode;
mod inputjudge;
mod inputtracker;
mod note;
mod offsetanimatedsprite2d;
