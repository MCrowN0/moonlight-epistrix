use std::collections::VecDeque;

use godot::prelude::*;

/// Intended, builtin class used for event handling in Project: Overkill.
///
/// It is recommended above using your own little quirky bullshit as it comes with better memory management and faster execution.
#[derive(GodotClass)]
#[class(base=Node)]
struct EventNode {
    events: VecDeque<(f64, Callable)>,
    base: Base<Node>,
}

#[godot_api]
impl INode for EventNode {
    fn init(base: Base<Node>) -> Self {
        Self {
            events: VecDeque::new(),
            base,
        }
    }
}

#[godot_api]
impl EventNode {
    /// Adds an event to the EventNode.
    ///
    /// # Arguments
    /// * `time` - The time at which the event is called.
    /// * `callable` - The callable event itself, can be anything, but it is recommended to use an anonymous function unless it is a repetitive event.
    ///
    /// ## Example
    /// ```
    /// add_event(31.0, func():
    ///     print("Hello World!")
    /// )
    /// ```
    #[func]
    pub fn add_event(&mut self, time: f64, callable: Callable) {
        let pos = self
            .events
            .binary_search_by(|e| e.0.partial_cmp(&time).unwrap())
            .unwrap_or_else(|e| e);
        self.events.insert(pos, (time, callable));
    }

    /// Adds multiple events to the EventNode.
    ///
    /// # Arguments
    /// * `events` - The events to add
    ///
    /// ## Example
    /// ```
    /// var events = [
    ///      [31.0, func():
    ///          print("Hello World! At 31.0"),
    ///      ],
    ///      [33.0, func():
    ///          print("Hello World! At 33.0"),
    ///      ]
    ///  ]
    ///
    ///  add_events(events)
    /// ```
    #[func]
    pub fn add_events(&mut self, events: Array<Array<Variant>>) {
        events.iter_shared().for_each(|event: Array<Variant>| {
            if let (Some(time_var), Some(callable_var)) = (event.get(0), event.get(1)) {
                if let (Ok(time), Ok(callable)) = (time_var.try_to::<f64>(), callable_var.try_to::<Callable>()) {
                    self.add_event(time, callable);
                }
            }
        });
    }

    /// Gets the time of the last event stored.
    ///
    /// # Returns
    /// The time of the last event stored.
    #[func]
    pub fn get_last_event_time(&self) -> f64 {
        self.events.back().map(|e| e.0).unwrap_or(0.0)
    }

    /// Gets the last event callable stored.
    ///
    /// # Returns
    /// The last event callable stored.
    #[func]
    pub fn get_last_event(&self) -> Callable {
        self.events
            .back()
            .map(|e| e.1.clone())
            .unwrap_or_else(|| Callable::invalid())
    }

    /// Calls the last callable event and then deletes it.
    #[func]
    pub fn call_last_event(&mut self) {
        if self.events.is_empty() {
            return;
        }

        self.get_last_event().call(&[]);
        self.events.pop_back();
    }

    /// Gets the time of the first event stored.
    ///
    /// # Returns
    /// The time of the first event stored.
    #[func]
    pub fn get_first_event_time(&self) -> f64 {
        self.events.get(0).map(|e| e.0).unwrap_or(0.0)
    }

    /// Gets the first event callable stored.
    ///
    /// # Returns
    /// The first event callable stored.
    #[func]
    pub fn get_first_event(&self) -> Callable {
        self.events
            .get(0)
            .map(|e: &(f64, Callable)| e.1.clone())
            .unwrap_or_else(|| Callable::invalid())
    }

    /// Calls the first callable event and then deletes it.
    #[func]
    pub fn call_first_event(&mut self) {
        if self.events.is_empty() {
            return;
        }

        self.events[0].1.call(&[]);
        self.events.pop_front();
    }
}
