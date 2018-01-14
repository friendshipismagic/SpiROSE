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

// LEDDriverConfig is the struct containing the LED Driver Config
// The serialized version is 48b long
#[derive(Debug, Deserialize)]
struct LEDDriverConfig {
    lodvth: u8,
    sel_td0: u8,
    sel_gdly: u8,
    xrefresh: u8,
    sel_gck_edge: u8,
    sel_pchg: u8,
    espwm: u8,
    lgse3: u8,
    sel_sck_edge: u8,
    lgse1: u8,
    ccb: u16,
    ccg: u16,
    ccr: u16,
    bc: u8,
    poker_trans_mode: u8,
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
        send(&mut spi, &decoded_command, &[]).unwrap();
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(command).expect("Command not recognized");
        get(&mut spi, &decoded_command, &[]).unwrap();
    } else if let Some(command_args) = matches.subcommand_matches("configure") {
        let config_file_url = command_args.value_of("config_file").unwrap();
        let mut config_file = File::open(config_file_url).expect("Configuration file not found");
        let mut serialized_conf = String::new();
        config_file
            .read_to_string(&mut serialized_conf)
            .expect("Unknown error when reading configuration file");
        // Unwrapping inside a LEDDriverConfig forces the full configuration to be available
        let led_config: LEDDriverConfig = toml::from_str(&serialized_conf).unwrap();
        let serialized_conf = serialize_conf(&led_config);
    }
}

fn serialize_conf(led_config: &LEDDriverConfig) -> io::Result<&[u8]> {
    println!("{:?}", led_config);
    // Serialization takes 48b, so 6 8b words
    let serialized_conf: &[u8] = &[0; 6];

    Ok(serialized_conf)
}

fn create_spi() -> io::Result<Spidev> {
    let mut spi = Spidev::open("/dev/null")?;

    let spi_options = SpidevOptions::new()
        .bits_per_word(8)
        .max_speed_hz(200_000)
        .mode(spidev::SPI_MODE_0)
        .build();

    //spi.configure(&spi_options)?;
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
    spi.write_all(&[command.id])?;

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
