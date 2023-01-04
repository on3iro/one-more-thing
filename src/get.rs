use one_more_thing::{get_random_things, thing_result::ThingResult, OmtGetError};
use rand::{thread_rng, Rng};

use crate::{
    config::Config,
    save_file::{SaveFile, SaveFilePath},
};

// TODO:
// Refactor -> getargs could simply be a struct directly used by clap
#[derive(Debug, Clone)]
pub struct GetArgs {
    pub dry: bool,
    pub things: Option<String>,
    pub file: String,
}

pub fn get(args: GetArgs) {
    let save_file_path = SaveFilePath(args.file);
    let save_file = match SaveFile::read(&save_file_path) {
        Ok(contents) => Some(contents),
        Err(_) => None,
    };

    let things = if let Some(things) = &args.things.clone() {
        serde_json::from_str(things).unwrap_or(vec![])
    } else {
        get_things_from_save_file_or_config(&save_file)
    };

    let result = match get_random_things(&things, 1, |max| {
        let index: u16 = thread_rng().gen_range(0..(u16::try_from(max).unwrap_or(0)));
        index
    }) {
        Ok(result) => result,
        Err(OmtGetError::ConversionError) => panic!("Integer-conversion failed"),
        Err(OmtGetError::NotEnoughThings) => {
            println!("Could not get another thing. Thing list is already empty!");
            return;
        }
    };

    println!(
        "Thing: {}",
        result
            .retrieved_things
            .last()
            .unwrap_or(&"Not Found".to_string())
    );

    if !args.dry {
        update_save_file(&save_file, save_file_path, result);
    }
}

fn update_save_file(
    save_file: &Option<SaveFile>,
    file_path: SaveFilePath,
    mut contents: ThingResult,
) {
    let mut already_retrieved_things = match save_file {
        Some(contents) => contents.retrieved_things.clone(),
        None => vec![],
    };

    already_retrieved_things.append(&mut contents.retrieved_things);

    let new_save = SaveFile(ThingResult {
        retrieved_things: already_retrieved_things,
        ..contents
    });

    if let Err(error) = new_save.write(file_path) {
        println!("Could not write save file: {}", error);
    };
}

/// Gets the "things" list written to a save file or falls back to the things written inside the
/// config file, if no save file exists.
fn get_things_from_save_file_or_config(save_file: &Option<SaveFile>) -> Vec<String> {
    match save_file.clone() {
        Some(contents) => contents.remaining_things.clone(),
        None => {
            let config = Config::read(Default::default()).unwrap_or(Config::default());
            config.things
        }
    }
}
