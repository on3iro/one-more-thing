// TODO:
// * README

mod config;
mod create;
mod get;
mod reset;
mod save_file;
mod undo;

use clap::{Parser, Subcommand};
use create::create;
use env_logger::Env;
use get::{get, GetArgs};
use reset::reset;
use save_file::DEFAULT_SAVE_FILE;
use undo::undo;

/// Available cli sub commands
#[derive(Subcommand)]
enum Commands {
    /// Creates a new omt project
    Create { project_name: String },

    /// Gets a single thing from the thinglist and saves the new list state to omt_save.yaml
    Get {
        /// Don't save the new state of the thing list
        #[arg(short, long, default_value = "false")]
        dry: bool,

        /// Uses the provided list string, instead of the list from the config file.
        /// NOTE: This might still overwrite an existing omt_save.yaml if you do not run the
        /// command with the --dry flag!
        ///
        /// # Example:
        /// omt get -t='["a", "b", "c"]'
        #[arg(short, long)]
        things: Option<String>,

        /// Specify save file
        #[arg(short, long, default_value = DEFAULT_SAVE_FILE)]
        file: String,
    },

    /// Removes the save file
    Reset {
        /// Specify save file
        #[arg(short, long, default_value = DEFAULT_SAVE_FILE)]
        file: String,
    },

    /// Moves the last picked item back to the thing list
    Undo {
        /// Specify save file
        #[arg(short, long, default_value = DEFAULT_SAVE_FILE)]
        file: String,
    },
}

/// Create and omt project to randomly pick things from a list one after another
#[derive(Parser)]
#[command(author, version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

fn main() {
    env_logger::Builder::from_env(Env::default().default_filter_or("warn"))
        .target(env_logger::Target::Stdout)
        .init();
    let cli = Cli::parse();

    match cli.command {
        Commands::Create { project_name } => create(&project_name),
        Commands::Get { dry, things, file } => get(GetArgs { dry, things, file }),
        Commands::Reset { file } => reset(file),
        Commands::Undo { file } => undo(file),
    }
}
