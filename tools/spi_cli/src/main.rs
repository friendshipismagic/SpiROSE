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
    len: usize
}

fn main() {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();

    let mut spi = create_spi().unwrap();

    if let Some(command_args) = matches.subcommand_matches("send") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(&command)
            .expect("Command not recognized");
        send(&mut spi, &decoded_command);
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = decode_command(&command)
            .expect("Command not recognized");
        send(&mut spi, &decoded_command);
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
        "blink_led" => Some(SpiCommand {id: 0xDE, len: 0}),
        "rotation" => Some(SpiCommand {id: 0x4C, len: 1}),
        "config" => Some(SpiCommand {id: 0xBF, len: 6}),
        _ => None
    }
}

fn send(spi: &mut Spidev, command: &SpiCommand) {
    spi.write(&vec!(command.id))
        .expect(&format!("Could not send command {:?}", &command));
}

fn get(spi: &mut Spidev, command: &SpiCommand) -> io::Result<Vec<u8>> {
    send(spi, command);
    let mut read_vec = Vec::with_capacity(command.len);
    spi.read(&mut read_vec);

    Ok(read_vec)
}
