//! Provides the result type used for omt randomization output and save files
//!
use serde::{Deserialize, Serialize};

/// Result containing a list of remaining things as wells as a list of already
/// retrieved things
#[derive(Debug, Default, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ThingResult {
    /// Remaining things from the original list
    pub remaining_things: Vec<String>,

    /// Elements that have been randomly retrieved from the original list in the
    /// order they were retrieved
    pub retrieved_things: Vec<String>,
}
