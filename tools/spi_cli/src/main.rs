#[macro_use]
extern crate clap;

use clap::App;

fn main() {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();
}
