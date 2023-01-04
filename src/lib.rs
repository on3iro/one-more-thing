#![warn(
    missing_docs,
    missing_copy_implementations,
    missing_debug_implementations
)]

//! Omt (one more thing) - randomization and helper functions

use thing_result::ThingResult;
use thiserror::Error;

pub mod thing_result;

/// Error that might occur when omt tries to randomly retrieve items
#[derive(Error, Debug, PartialEq, Eq, Copy, Clone)]
pub enum OmtGetError {
    /// Occurs when there are not enough items to retrieve by the specified amount
    #[error("Not enough things to retrieve in input list")]
    NotEnoughThings,

    /// Occurs when integer conversion fails
    #[error("Could not convert between u16 and usize")]
    ConversionError,
}

type Algorithm = fn(max: usize) -> u16;

/// Given a list of things (strings) randomly retrieves the specified amount from
/// the list and returns a result containing the randomly retrieved items as well
/// as the original list minus the retrieved items.
/// The given algorithm specifies how each index to select an item is determined.
///
/// # Examples
///
/// ```
/// use one_more_thing::get_random_things;
/// use rand::{thread_rng, Rng};
///
/// fn main() {
///     let result = get_random_things(&vec!["a".to_string(), "b".to_string()], 1, |max| {
///         let index: u16 = thread_rng().gen_range(0..(u16::try_from(max).unwrap_or(0)));
///         index
///     })
///     .unwrap();
///
///     println!("Result: {}", result.retrieved_things[0]);
/// }
/// ```
pub fn get_random_things(
    things: &Vec<String>,
    amount: u16,
    algorithm: Algorithm,
) -> Result<ThingResult, OmtGetError> {
    if amount > u16::try_from(things.len()).unwrap_or(0) {
        return Err(OmtGetError::NotEnoughThings);
    }

    let mut retrieved_things = vec![];
    let mut remaining_things = things.clone();

    for _ in 0..amount {
        let index = usize::try_from(algorithm(remaining_things.len()));

        match index {
            Ok(index) => {
                let thing = remaining_things.remove(index);
                retrieved_things.push(thing);
            }
            Err(_) => return Err(OmtGetError::ConversionError),
        }
    }

    Ok(ThingResult {
        remaining_things,
        retrieved_things,
    })
}

#[cfg(test)]
mod test {
    use crate::{get_random_things, OmtGetError};

    // Simple algorith always returning zero.
    // That way we know for sure, which item will be "randomly" selected during
    // a test case.
    fn test_algorithm(_max: usize) -> u16 {
        return 0;
    }

    #[test]
    fn returns_correct_amount() {
        let result = get_random_things(
            &vec![
                "Finn".to_string(),
                "Jake".to_string(),
                "PB".to_string(),
                "Bemo".to_string(),
                "Ice King".to_string(),
            ],
            2,
            test_algorithm,
        )
        .unwrap();
        assert_eq!(result.retrieved_things.len(), 2);
        assert_eq!(result.remaining_things.len(), 3);
    }

    #[test]
    fn returns_error_if_amount_is_larger_than_list() {
        let result = get_random_things(&vec![], 2, test_algorithm);

        assert_eq!(result, Err(OmtGetError::NotEnoughThings));
    }

    #[test]
    fn returns_things_list_and_remaining_list() {
        let result = get_random_things(
            &vec![
                "Finn".to_string(),
                "Jake".to_string(),
                "PB".to_string(),
                "Bemo".to_string(),
                "Ice King".to_string(),
            ],
            2,
            test_algorithm,
        )
        .unwrap();

        assert_eq!(
            result.retrieved_things,
            vec!["Finn".to_string(), "Jake".to_string()]
        );
        assert_eq!(
            result.remaining_things,
            vec!["PB".to_string(), "Bemo".to_string(), "Ice King".to_string()]
        );
    }
}
