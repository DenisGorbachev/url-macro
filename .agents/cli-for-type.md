# Concepts for CLI-for-type

## Target type

The type whose methods are exposed through a CLI and invoked by child commands.

Examples:

- Rust example.
  - ```rust
    //! In this example, all types are in the same file. In real code, the types must be in their own files according to project guidelines.

    use std::io::stdout;
    use clap::{Parser, Subcommand};
    use derive_new::new;
    use errgonomic::handle;
    use secrecy::SecretString;
    use subtype::{subtype, subtype_string, subtype_u64};
    use thiserror::Error;

    use FooSubcommand::*;

    subtype! {
        #[derive(Clone, Debug)]
        pub struct FooApiKey(SecretString)
    }

    impl core::str::FromStr for FooApiKey {
        type Err = core::convert::Infallible;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            Ok(FooApiKey::new(SecretString::from(s.to_owned())))
        }
    }

    subtype_u64! {
        pub struct UserId(u64)
    }

    impl core::str::FromStr for UserId {
        type Err = core::num::ParseIntError;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            s.parse::<u64>().map(Self::new)
        }
    }

    subtype_u64! {
        pub struct UsersPage(u64)
    }

    impl core::str::FromStr for UsersPage {
        type Err = core::num::ParseIntError;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            s.parse::<u64>().map(Self::new)
        }
    }

    subtype_string! {
        pub struct UserName(String)
    }

    impl core::str::FromStr for UserName {
        type Err = core::convert::Infallible;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            Ok(Self::new(s))
        }
    }

    #[derive(Clone, Debug)]
    pub struct User {
        pub id: UserId,
        pub name: UserName,
    }

    #[derive(new)]
    pub struct FooClient {
        api_key: FooApiKey,
    }

    impl FooClient {
        pub fn users(&self, _page: UsersPage) -> Result<Vec<User>, FooClientUsersError> {
            use FooClientUsersError::*;
            let _ = NotImplemented {};
            todo!()
        }

        pub fn set_user_name(&self, _id: UserId, _name: &UserName) -> Result<(), FooClientSetUserNameError> {
            use FooClientSetUserNameError::*;
            let _ = NotImplemented {};
            todo!()
        }
    }


    #[derive(Error, Debug)]
    pub enum FooClientUsersError {
        #[error("foo client users operation is not implemented")]
        NotImplemented {},
    }

    #[derive(Error, Debug)]
    pub enum FooClientSetUserNameError {
        #[error("foo client set user name operation is not implemented")]
        NotImplemented {},
    }

    #[derive(Parser, Debug)]
    #[command(author, version, about, propagate_version = true)]
    pub struct FooCommand {
        #[arg(long, env = "FOO_API_KEY")]
        api_key: FooApiKey,

        #[command(subcommand)]
        subcommand: FooSubcommand,
    }

    #[derive(Subcommand, Clone, Debug)]
    pub enum FooSubcommand {
        Users(FooUsersCommand),
        SetUserName(FooSetUserNameCommand),
    }

    impl FooCommand {
        pub async fn run(self) -> Result<(), FooCommandRunError> {
            use FooCommandRunError::*;
            let Self {
                api_key,
                subcommand,
            } = self;
            let client = FooClient::new(api_key);
            match subcommand {
                Users(command) => map_err!(command.run(&client).await, UsersCommandRunFailed),
                SetUserName(command) => map_err!(command.run(&client).await, SetUserNameCommandRunFailed),
            }
        }
    }

    #[derive(Error, Debug)]
    pub enum FooCommandRunError {
        #[error("failed to run users command")]
        UsersCommandRunFailed { source: FooUsersCommandRunError },
    
        #[error("failed to run set user name command")]
        SetUserNameCommandRunFailed { source: FooSetUserNameCommandRunError },
    }

    #[derive(Parser, Debug)]
    pub struct FooUsersCommand {
        #[arg(long)]
        page: UsersPage,
    }

    impl FooUsersCommand {
        pub async fn run(self, client: &FooClient) -> Result<(), FooUsersCommandRunError> {
            use FooUsersCommandRunError::*;
            let Self {
                page,
            } = self;
            let mut stdout = stdout();
            let users = handle!(client.users(page), UsersFailed, page);
            handle!(serde_json::to_writer_pretty(&mut stdout, &users), ToWriterPrettyFailed, users);
            Ok(())
        }
    }

    #[derive(Error, Debug)]
    pub enum FooUsersCommandRunError {
        #[error("failed to fetch users for page '{page}'")]
        UsersFailed { source: FooClientUsersError, page: UsersPage },
        #[error("failed to write users to stdout")]
        ToWriterPrettyFailed { source: serde_json::Error, users: Vec<User> },
    }

    #[derive(Parser, Debug)]
    pub struct FooSetUserNameCommand {
        #[arg(long)]
        user_id: UserId,

        #[arg(long)]
        name: UserName,
    }

    impl FooSetUserNameCommand {
        pub async fn run(self, client: &FooClient) -> Result<Vec<User>, FooSetUserNameCommandRunError> {
            use FooSetUserNameCommandRunError::*;
            let Self {
                user_id,
                name,
            } = self;
            handle!(client.set_user_name(user_id, &name), SetUserNameFailed, user_id, name);
            Ok(())
        }
    }

    #[derive(Error, Debug)]
    pub enum FooSetUserNameCommandRunError {
        #[error("failed to set user name '{name}' for user '{user_id}'")]
        SetUserNameFailed { source: FooClientSetUserNameError, user_id: UserId, name: UserName },
    }
    ```

Requirements:

- Must be constructible by the parent command.
- Must expose at least one public method that can be invoked by a child command.

Notes:

- The target type should not parse CLI arguments itself.

## Parent command

The command that constructs the target type and delegates execution to the selected child command.

Requirements:

- Must have fields for all inputs needed to construct the target type.
- Must construct an instance of the target type.
- Must pass the constructed instance of the target type to the selected child command.

Notes:

- The parent command isolates CLI parsing from domain logic.

## Child command

A subcommand that wraps one target-type method and maps CLI arguments to that method.

Requirements:

- Must have a field for each argument of the wrapped method.
- Must call the wrapped method in its run implementation.
- Must return an error type that wraps the method error and the relevant argument values.
- Must write the results to stdout in an efficient way:
  - Must serialize the results using `serde_json`
  - Must use `serde_json::to_writer_pretty`

Notes:

- Child commands should not construct the target type themselves.
