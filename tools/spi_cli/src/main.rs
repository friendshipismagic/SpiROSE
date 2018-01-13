#[macro_use]
extern crate clap;
extern crate spidev;

use std::io;
use std::io::prelude::*;
use clap::App;
use spidev::{Spidev, SpidevOptions};

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
        let decoded_command = decode_command(&command).expect("Command not recognized");
        send(&mut spi, &decoded_command, None);
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(&command).expect("Command not recognized");
        send(&mut spi, &decoded_command, None);
    }
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

fn send(spi: &mut Spidev, command: &SpiCommand, command_args: Option<&[u8]>) -> io::Result<()> {
    spi.write(&vec![command.id]);

    // Send optionnal arguments with the command (for instance, configuration data)
    if let Some(command_args) = command_args {
        spi.write(command_args);
    }

    Ok(())
}

fn get(spi: &mut Spidev, command: &SpiCommand, command_args: Option<&[u8]>) -> io::Result<Vec<u8>> {
    send(spi, command, command_args);
    let mut read_vec = Vec::with_capacity(command.recv_len);
    spi.read(&mut read_vec);

    Ok(read_vec)
}
