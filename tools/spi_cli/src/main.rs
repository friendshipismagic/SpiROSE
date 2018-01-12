#[macro_use]
extern crate clap;

use clap::App;

fn main() {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();

    if let Some(command_args) = matches.subcommand_matches("send") {
        let command = command_args.value_of("command").unwrap();
        println!("{:?}", command);
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        println!("{:?}", command);
    }
}
