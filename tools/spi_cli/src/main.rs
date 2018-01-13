#[macro_use]
extern crate clap;
#[macro_use]
extern crate serde_derive;
extern crate spidev;
extern crate toml;

use std::io;
use std::io::prelude::*;
use std::fs::File;
use clap::App;
use spidev::{Spidev, SpidevOptions};
use toml::Value;

#[derive(Debug, Deserialize)]
struct LEDDriverConfig {
    lodvth: u8,
    sel_td0: u8,
    sel_gdly: bool,
    xrefresh: bool,
    sel_gck_edge: bool,
    sel_pchg: bool,
    espwm: bool,
    lgse3: bool,
    sel_sck_edge: bool,
    lgse1: u8,
    ccb: u16,
    ccg: u16,
    ccr: u16,
    bc: u8,
    poker_trans_mode: bool,
    lgse2: u8,
}

#[derive(Debug)]
struct SpiCommand {
    id: u8,
    recv_len: usize,
}

fn main() {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();

    let mut spi = create_spi().unwrap();

    if let Some(command_args) = matches.subcommand_matches("send") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(command).expect("Command not recognized");
        send(&mut spi, &decoded_command, &vec![]);
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(command).expect("Command not recognized");
        get(&mut spi, &decoded_command, &vec![]);
    } else if let Some(command_args) = matches.subcommand_matches("configure") {
        let config_file_url = command_args.value_of("config_file").unwrap();
        let mut config_file = File::open(config_file_url).expect("Configuration file not found");
        let mut serialized_conf = String::new();
        config_file
            .read_to_string(&mut serialized_conf)
            .expect("Unknown error when reading configuration file");
        let led_config = serialized_conf.parse::<Value>().unwrap();
        check_configuration(&led_config);
    }
}

fn check_configuration(led_config: &Value) -> io::Result<()> {
    println!("{:?}", led_config);
    Ok(())
}

fn create_spi() -> io::Result<Spidev> {
    let mut spi = Spidev::open("/dev/null")?;

    let spi_options = SpidevOptions::new()
        .bits_per_word(8)
        .max_speed_hz(200_000)
        .mode(spidev::SPI_MODE_0)
        .build();

    spi.configure(&spi_options)?;
    Ok(spi)
}

fn decode_command(command: &str) -> Option<SpiCommand> {
    match command {
        "blink_led" => Some(SpiCommand {
            id: 0xDE,
            recv_len: 0,
        }),
        "rotation" => Some(SpiCommand {
            id: 0x4C,
            recv_len: 1,
        }),
        "config" => Some(SpiCommand {
            id: 0xBF,
            recv_len: 6,
        }),
        _ => None,
    }
}

fn send(spi: &mut Spidev, command: &SpiCommand, command_args: &[u8]) -> io::Result<()> {
    spi.write_all(&vec![command.id])?;

    // Send optionnal arguments with the command (for instance, configuration data)
    if !command_args.is_empty() {
        spi.write_all(command_args)?;
    }

    Ok(())
}

fn get(spi: &mut Spidev, command: &SpiCommand, command_args: &[u8]) -> io::Result<Vec<u8>> {
    send(spi, command, command_args)?;
    let mut read_vec = vec![0; command.recv_len];
    spi.read_exact(&mut read_vec)?;

    Ok(read_vec)
}
