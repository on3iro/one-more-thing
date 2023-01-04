use std::fs::create_dir;

use crate::config::{Config, ConfigFilePath, DEFAULT_CONFIG_FILE};

// TODO: proper error handling & documentation
pub fn create(project_name: &str) {
    create_dir(project_name).unwrap();

    let config_path = ConfigFilePath(format!("{}/{}", project_name, DEFAULT_CONFIG_FILE));

    if let Err(error) = Config::default().write(config_path) {
        println!("Could not create config file: {}", error);
    }
}
