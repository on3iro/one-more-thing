use anyhow::Context;
use serde::{Deserialize, Serialize};
use std::{fs::write, ops::Deref, path::Path};

pub const DEFAULT_CONFIG_FILE: &str = "omt.yaml";
pub struct ConfigFilePath(pub String);

impl Deref for ConfigFilePath {
    type Target = String;

    fn deref(&self) -> &String {
        &self.0
    }
}

impl Default for ConfigFilePath {
    fn default() -> Self {
        ConfigFilePath(DEFAULT_CONFIG_FILE.to_string())
    }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Input list to randomly get values from
    pub things: Vec<String>,
}

impl Config {
    pub fn write(self: &Self, path: ConfigFilePath) -> anyhow::Result<()> {
        let serialized_config =
            serde_yaml::to_string(self).context("Could not serialize config")?;

        write(&*path, serialized_config).context("Could not write config to file")?;

        Ok(())
    }

    pub fn read(path: ConfigFilePath) -> anyhow::Result<Self> {
        let config_file_contents =
            std::fs::read_to_string(Path::new(&*path)).context("Could not read config file")?;

        let config: Config = serde_yaml::from_str(&config_file_contents)
            .context("Could not parse config file content")?;

        Ok(config)
    }
}
