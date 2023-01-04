use one_more_thing::thing_result::ThingResult;

use crate::save_file::{SaveFile, SaveFilePath};

pub fn undo(file: String) {
    let save_file_path = SaveFilePath(file);
    let save_file = match SaveFile::read(&save_file_path) {
        Ok(contents) => Some(contents),
        Err(_) => None,
    };

    let old_save = match save_file {
        Some(contents) => contents,
        None => {
            println!("Nothing to undo");
            return;
        }
    };

    let last_retrieved_thing = match old_save.retrieved_things.last() {
        Some(thing) => thing,
        None => {
            println!("Nothing to undo");
            return;
        }
    };

    println!("Moving <{}> back to things", last_retrieved_thing);

    let new_save = SaveFile(ThingResult {
        retrieved_things: (old_save.retrieved_things[0..old_save.retrieved_things.len() - 1])
            .to_vec(),
        remaining_things: [
            old_save.remaining_things.clone(),
            vec![last_retrieved_thing.to_owned()],
        ]
        .concat(),
    });

    if let Err(error) = new_save.write(save_file_path) {
        println!("Could not write save file: {}", error);
    };
}
