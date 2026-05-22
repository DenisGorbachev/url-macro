# CLI guidelines

## Dependencies

- `clap` (features: at least "derive", "env")
- `tokio` (features: at least "macros", "rt", "rt-multi-thread")
- `errgonomic`
- `thiserror`

## File layout and required items

### File `src/main.rs`

- Must define a `main` entrypoint
- Must define a `verify_cli` test for the top-level command exactly as in the example below (with `debug_assert`)

Example:

```rust
use clap::Parser;
use errgonomic::exit_result;
use my_crate_name::Command;
use std::process::ExitCode;

#[tokio::main]
async fn main() -> ExitCode {
    let args = Command::parse();
    let result = args.run().await;
    exit_result(result)
}

#[test]
fn verify_cli() {
    use clap::CommandFactory;
    Command::command().debug_assert();
}
```

### File `src/command.rs`

- Must define a [command-like struct](#command-like-struct) named `Command`
- Must define a [subcommand-like enum](#subcommand-like-enum) named `Subcommand`

Example:

```rust
use std::process::ExitCode;
use Subcommand::*;
use errgonomic::map_err;
use thiserror::Error;

#[derive(clap::Parser, Debug)]
#[command(author, version, about, propagate_version = true)]
pub struct Command {
    #[command(subcommand)]
    subcommand: Subcommand,
}

#[derive(clap::Subcommand, Clone, Debug)]
pub enum Subcommand {
    Print(PrintCommand),
}

impl Command {
    pub async fn run(self) -> Result<ExitCode, CommandRunError> {
        use CommandRunError::*;
        let Self {
            subcommand,
        } = self;
        match subcommand {
            Print(command) => map_err!(command.run().await, PrintCommandRunFailed),
        }
    }
}

#[derive(Error, Debug)]
pub enum CommandRunError {
    #[error("failed to run print command")]
    PrintCommandRunFailed { source: PrintCommandRunError },
}

mod print_command;

pub use print_command::*;
```

## Definitions

### Command-like struct

A struct that contains fields for CLI arguments.

- Must have a name that is a concatenation of all command names leading up to and including this command name, and ends with `Command` (see example above)
- Must derive `clap::Parser`
- Must be attached to a parent module: if it's a top-level command: `src/lib.rs`, else: `src/command.rs`
- May contain a `subcommand` field annotated with `#[command(subcommand)]`
- Must have a `pub async fn run`
  - Must return a `Result` with `ExitCode`
  - If it contains a `subcommand` field: must match on `subcommand` and call `run` of each command

Command example:

- Name: `DbDownloadYcombinatorStartupsCommand`
- File: `src/command/db_download_ycombinator_startups_command.rs` (attached to `src/command.rs`)
- Shell command: `cargo run -- db download ycombinator-startups`

### Subcommand-like enum

An enum that contains variants for CLI subcommands.

- Must have a name that is a concatenation of all command names leading up to and including this command name, and ends with `Subcommand` (see example above)
- Must derive `clap::Subcommand`
- Must be located in the same file as its parent command struct
- Each variant must be a tuple variant containing exactly one command

Subcommand example:

- Name: `DbDownloadSubcommand`
- File: `src/cli/db_command/db_download_command.rs` (same file as its parent `DbDownloadCommand`)

### Proxy command-like struct

A [command-like struct](#command-like-struct) that has a `subcommand` field and calls `run` on each subcommand.

Proxy command example:

- Name: `DbCommand`
- File: `src/command/db_command.rs` (attached to `src/command.rs`)
