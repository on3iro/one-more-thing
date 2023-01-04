use crate::save_file::{SaveFile, SaveFilePath};

pub fn reset(file: String) {
    let save_file_path = SaveFilePath(file);

    if let Err(error) = SaveFile::remove(&save_file_path) {
        println!("Could not remove save file: {}", error);
    };
}
