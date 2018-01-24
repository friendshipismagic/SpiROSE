#[macro_use]
extern crate clap;
#[macro_use]
extern crate error_chain;
extern crate packed_struct;
#[macro_use]
extern crate packed_struct_codegen;
#[macro_use]
extern crate serde_derive;
extern crate spidev;
extern crate toml;

use std::io;
use std::io::prelude::*;
use std::fs::File;
use clap::App;
use spidev::{Spidev, SpidevOptions};
use packed_struct::prelude::*;

mod errors {
    error_chain! {
        foreign_links {
            Toml(::toml::de::Error);
            Io(::io::Error);
        }
    }
}

// LEDDriverConfig is the struct containing the LED Driver Config
// The serialized version is 48b long
// As we send MSB for each packet, but LSB
#[derive(Debug, Deserialize, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct LEDDriverConfig {
    #[packed_field(bits = "46..47")]
    lodvth: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "44..45")]
    sel_td0: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "43")]
    sel_gdly: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "42")]
    xrefresh: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "41")]
    sel_gck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "40")]
    sel_pchg: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "39")]
    espwm: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "38")]
    lgse3: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "37")]
    sel_sck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "34..36")]
    lgse1: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "25..33", endian = "msb")]
    ccb: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "16..24", endian = "msb")]
    ccg: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "7..15", endian = "msb")]
    ccr: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "4..6")]
    bc: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "3")]
    poker_trans_mode: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "0..2")]
    lgse2: Integer<u8, ::packed_bits::Bits3>,
}

static COMMANDS: [&'static str; 6] = [
    "enable_rgb",
    "disable_rgb",
    "get_rotation",
    "get_speed",
    "get_config",
    "get_debug",
];

#[derive(Debug)]
struct SpiCommand {
    id: u8,
    recv_len: usize,
}

impl SpiCommand {
    fn new(id: u8) -> SpiCommand {
        SpiCommand::new_with_len(id, 0)
    }

    fn new_with_len(id: u8, recv_len: usize) -> SpiCommand {
        SpiCommand { id, recv_len }
    }

    fn decode(command: &str) -> SpiCommand {
        match command {
            "enable_rgb" => SpiCommand::new(0xe0),
            "disable_rgb" => SpiCommand::new(0xd0),
            "get_rotation" => SpiCommand::new_with_len(0x4c, 2),
            "get_speed" => SpiCommand::new_with_len(0x4d, 2),
            "get_config" => SpiCommand::new_with_len(0xbf, 6),
            "get_debug" => SpiCommand::new_with_len(0xde, 4),
            _ => unreachable!(),
        }
    }
}

fn main() {
    match run() {
        Ok(_) => {}
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}

fn run() -> errors::Result<()> {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();

    let spi_dev = matches.value_of("device").unwrap();
    let verbose = matches.is_present("verbose");
    let dummy = spi_dev == "none";
    let mut spi = create_spi(if dummy { "/dev/null" } else { spi_dev }, !dummy)?;
    if let Some(command_args) = matches.subcommand_matches("send_config") {
        let config_file_url = command_args.value_of("config_file").unwrap();
        let mut config_file = File::open(config_file_url).map_err(|e| {
            format!(
                "Cannot open configuration file `{}': {}",
                config_file_url, e
            )
        })?;
        let mut serialized_conf = String::new();
        config_file.read_to_string(&mut serialized_conf)?;
        // Unwrapping inside a LEDDriverConfig forces the full configuration to be available
        let led_config: LEDDriverConfig = toml::from_str(&serialized_conf)?;
        transfer(
            &mut spi,
            &SpiCommand::decode("get_config"),
            &led_config.pack(),
            verbose,
            dummy,
        )?;
    } else {
        for c in COMMANDS.iter() {
            if matches.subcommand_matches(c).is_some() {
                transfer(&mut spi, &SpiCommand::decode(c), &[], verbose, dummy)?;
            }
        }
    }
    Ok(())
}

fn create_spi(spi_dev: &str, configure: bool) -> errors::Result<Spidev> {
    let mut spi =
        Spidev::open(spi_dev).map_err(|e| format!("Cannot open SPI device `{}': {}", spi_dev, e))?;

    let spi_options = SpidevOptions::new()
        .bits_per_word(8)
        .max_speed_hz(200_000)
        .mode(spidev::SPI_MODE_0)
        .build();

    if configure {
        spi.configure(&spi_options)?;
    }

    Ok(spi)
}

fn transfer<T: Write + Read>(
    spi: &mut T,
    command: &SpiCommand,
    command_args: &[u8],
    verbose: bool,
    dummy: bool,
) -> errors::Result<Vec<u8>> {
    // Transmit the command and the arguments as one SPI transaction.
    let mut transaction = Vec::with_capacity(1 + command_args.len());
    transaction.push(command.id);
    transaction.extend(command_args);
    if verbose {
        println!("Sending {:?}", transaction);
    }
    spi.write_all(&transaction)?;
    // Receive answer if applicable
    let mut read_vec = vec![0; command.recv_len];
    if verbose {
        println!(
            "Waiting for {} byte{}",
            command.recv_len,
            if command.recv_len == 1 { "" } else { "s" }
        );
    }
    if command.recv_len > 0 {
        if !dummy {
            spi.read_exact(&mut read_vec)?;
        }
        println!(
            "{}",
            read_vec
                .iter()
                .map(|x| format!("{}", x))
                .collect::<Vec<_>>()
                .join(",")
        );
    }
    Ok(read_vec)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serialize() {
        let led_config: LEDDriverConfig =
            toml::from_str(include_str!("../data/test_conf.toml")).unwrap();
        assert_eq!(&led_config.pack(), &[50, 1, 0, 128, 79, 245]);
    }
}
