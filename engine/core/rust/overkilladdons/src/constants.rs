/// List of normalized direction names used by the rhythm system.
pub const DIRECTIONS: [&str; 4] = ["left", "down", "up", "right"];

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
/// Direction enum representing the four possible input lanes.
pub enum Direction {
    Left,
    Down,
    Up,
    Right,
}