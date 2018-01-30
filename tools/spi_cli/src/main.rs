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
use std::iter;
use std::io::prelude::*;
use std::fs::File;
use std::str::FromStr;

use clap::App;
use spidev::{Spidev, SpidevOptions};
use packed_struct::prelude::*;


mod errors {
    error_chain! {
        foreign_links {
            Toml(::toml::de::Error);
            Io(::io::Error);
            ParseInt(::std::num::ParseIntError);
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

static COMMANDS: [&'static str; 8] = [
    "enable_rgb",
    "disable_rgb",
    "get_rotation",
    "get_speed",
    "get_config",
    "get_debug",
    "manage",
    "release"
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
            "enable_mux" => SpiCommand::new_with_len(0xe1, 1),
            "disable_mux" => SpiCommand::new_with_len(0xd1, 1),
            "get_rotation" => SpiCommand::new_with_len(0x4c, 2),
            "get_speed" => SpiCommand::new_with_len(0x4d, 2),
            "get_config" => SpiCommand::new_with_len(0xbf, 6),
            "get_debug" => SpiCommand::new_with_len(0xde, 4),
            "send_driver" => SpiCommand::new_with_len(0xee, 49),
            "send_driver_data" => SpiCommand::new_with_len(0xdd, 7),
            "manage" => SpiCommand::new(0xfa),
            "release" => SpiCommand::new(0xfe),
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

    match matches.subcommand() {
        ("send_config", Some(command_args)) => {
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
            Ok(())
        },

        ("enable_mux", Some(command_args)) => {
            let mux_ids = command_args.values_of("mux_id")
                .unwrap()
                .map(|mux_id| u8::from_str(mux_id).unwrap());
            for mux_id in mux_ids {
                transfer(&mut spi, &SpiCommand::decode("enable_mux"), &[mux_id], verbose, dummy)?;
            }
            Ok(())
        },

        ("disable_mux", Some(command_args)) => {
            let mux_ids = command_args.values_of("mux_id")
                .unwrap()
                .map(|mux_id| u8::from_str(mux_id).unwrap());
            for mux_id in mux_ids {
                transfer(&mut spi, &SpiCommand::decode("disable_mux"), &[mux_id], verbose, dummy)?;
            }
            Ok(())
        },

        ("send_driver_data", Some(command_args)) => {
            let driver_id = u8::from_str(command_args.value_of("driver_id").unwrap())?;
            let driver_data = u64::from_str_radix(command_args.value_of("driver_data").unwrap(), 2)?;
            let mut transaction = Vec::with_capacity(7);
            transaction.push(driver_id);
            transaction.extend((2..8).map(|n| (driver_data >> ((7-n)*8)) as u8));

            transfer(&mut spi, &SpiCommand::decode("send_driver_data"), &transaction, verbose, dummy)?;
            Ok(())
        },

        ("send_driver", Some(command_args)) => {
            let file_name = command_args.value_of("filename").unwrap();
            let mut driver_file = File::open(file_name).map_err(|e| {
                format!(
                    "Cannot open configuration file `{}': {}",
                    file_name, e
                    )
            })?;

            let mut data = String::new();
            driver_file.read_to_string(&mut data)?;
            let data = data.trim();
            let mut transaction = Vec::with_capacity(49);
            for i in 0..48.min(data.len()/8) {
                let word = &data[i*8..(i+1)*8];
                transaction.push(u8::from_str_radix(&word, 2).unwrap());
            }
            let missing = 49 - transaction.len();
            transaction.extend(iter::repeat(0).take(missing));
            transfer(&mut spi, &SpiCommand::decode("send_driver"), &transaction, verbose, dummy)?;
            Ok(())
        },
        (name, _) =>  {
            for c in COMMANDS.iter() {
                if c == &name {
                    transfer(&mut spi, &SpiCommand::decode(c), &[], verbose, dummy)?;
                }
            }
            Ok(())
        }
    }
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
