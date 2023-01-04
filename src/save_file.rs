use anyhow::Context;
use std::fs::write;
use std::{ops::Deref, path::Path};

use one_more_thing::thing_result::ThingResult;

#[derive(Debug, Clone)]
pub struct SaveFile(pub ThingResult);

impl Deref for SaveFile {
    type Target = ThingResult;

    fn deref(&self) -> &ThingResult {
        &self.0
    }
}

pub const DEFAULT_SAVE_FILE: &str = "omt_save.yaml";

#[derive(Debug, Clone)]
pub struct SaveFilePath(pub String);

impl AsRef<std::ffi::OsStr> for SaveFilePath {
    fn as_ref(&self) -> &std::ffi::OsStr {
        &std::ffi::OsStr::new(&self.0)
    }
}

impl AsRef<Path> for SaveFilePath {
    fn as_ref(&self) -> &Path {
        Path::new(&self.0)
    }
}

impl Deref for SaveFilePath {
    type Target = String;

    fn deref(&self) -> &String {
        &self.0
    }
}

impl Default for SaveFilePath {
    fn default() -> Self {
        SaveFilePath(DEFAULT_SAVE_FILE.to_string())
    }
}

impl SaveFile {
    pub fn write(self: &Self, path: SaveFilePath) -> anyhow::Result<()> {
        let serialized_save_file =
            serde_yaml::to_string(&**self).context("Could not serialize save file")?;
        write(&*path, serialized_save_file).context("Could not write save file contents")?;
        Ok(())
    }

    pub fn read(path: &SaveFilePath) -> anyhow::Result<SaveFile> {
        let save_file_contents =
            std::fs::read_to_string(Path::new(&path)).context("Could not read save file")?;

        let save_file: ThingResult = serde_yaml::from_str(&save_file_contents)
            .context("Could not parse save file content")?;

        Ok(SaveFile(save_file))
    }

    pub fn remove(path: &SaveFilePath) -> anyhow::Result<()> {
        std::fs::remove_file(path)?;

        Ok(())
    }
}
