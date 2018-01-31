#[macro_use]
extern crate clap;
#[macro_use]
extern crate error_chain;
extern crate image;
extern crate packed_struct;
#[macro_use]
extern crate packed_struct_codegen;
#[macro_use]
extern crate serde_derive;
extern crate spidev;
extern crate toml;

mod commands;
mod framebuffer;
mod units;

use std::io;
use std::io::prelude::*;
use std::fs::File;
use std::str::FromStr;

use clap::App;
use commands::*;
use framebuffer::*;
use spidev::{Spidev, SpidevOptions};
use packed_struct::prelude::*;

mod errors {
    error_chain! {
        foreign_links {
            Toml(::toml::de::Error);
            Io(::io::Error);
            ParseInt(::std::num::ParseIntError);
            Image(::image::ImageError);
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
    let freq = units::parse(matches.value_of("frequency").unwrap())?;
    let mut spi = create_spi(
        if dummy { "/dev/null" } else { spi_dev },
        freq,
        !dummy,
        verbose,
    )?;

    match matches.subcommand() {
        ("send_config", Some(command_args)) => {
            let file = command_args.value_of("config_file").unwrap();
            let mut file = File::open(file)
                .map_err(|e| format!("Cannot open configuration file `{}': {}", file, e))?;
            let mut serialized_conf = String::new();
            file.read_to_string(&mut serialized_conf)?;
            // Unwrapping inside a LEDDriverConfig forces the full configuration to be available
            let led_config: LEDDriverConfig = toml::from_str(&serialized_conf)?;
            transfer(&mut spi, &GET_CONFIG, &led_config.pack(), verbose, dummy)?;
            Ok(())
        }

        ("enable_mux", Some(command_args)) => {
            let mux_ids = command_args
                .values_of("mux_id")
                .unwrap()
                .map(|mux_id| u8::from_str(mux_id).unwrap());
            for mux_id in mux_ids {
                transfer(&mut spi, &ENABLE_MUX, &[mux_id], verbose, dummy)?;
            }
            Ok(())
        }

        ("disable_mux", Some(command_args)) => {
            let mux_ids = command_args
                .values_of("mux_id")
                .unwrap()
                .map(|mux_id| u8::from_str(mux_id).unwrap());
            for mux_id in mux_ids {
                transfer(&mut spi, &DISABLE_MUX, &[mux_id], verbose, dummy)?;
            }
            Ok(())
        }

        ("send_driver_pokered", Some(command_args)) => send_binary_file(
            &mut spi,
            &SEND_DRIVER_POKERED,
            command_args.value_of("filename").unwrap(),
            54,
            verbose,
            dummy,
        ),

        ("send_driver_rgb", Some(command_args)) => send_binary_file(
            &mut spi,
            &SEND_DRIVER_RGB,
            command_args.value_of("filename").unwrap(),
            48,
            verbose,
            dummy,
        ),

        ("read_pixel", Some(command_args)) => {
            let x = command_args.value_of("x").unwrap().parse::<u8>()?;
            let y = command_args.value_of("y").unwrap().parse::<u8>()?;
            let p = read_pixel(&mut spi, x, y, verbose, dummy)?;
            println!("({}, {}, {})", p.r, p.g, p.b);
            Ok(())
        }

        ("write_pixel", Some(command_args)) => {
            let x = command_args.value_of("x").unwrap().parse::<u8>()?;
            let y = command_args.value_of("y").unwrap().parse::<u8>()?;
            let r = command_args.value_of("r").unwrap().parse::<u8>()?;
            let g = command_args.value_of("g").unwrap().parse::<u8>()?;
            let b = command_args.value_of("b").unwrap().parse::<u8>()?;
            write_pixel(&mut spi, x, y, &Pixel { r, g, b }, verbose, dummy)
        }

        ("color", Some(command_args)) => {
            let r = command_args.value_of("r").unwrap().parse::<u8>()?;
            let g = command_args.value_of("g").unwrap().parse::<u8>()?;
            let b = command_args.value_of("b").unwrap().parse::<u8>()?;
            color(&mut spi, &Pixel { r, g, b }, verbose, dummy)
        }

        ("send_image", Some(command_args)) => {
            let file = command_args.value_of("filename").unwrap();
            let img =
                image::open(file).map_err(|e| format!("Cannot open image `{}': {}", file, e))?;
            send_image(&mut spi, &img, verbose, dummy)
        }

        ("get_image", Some(command_args)) => {
            let file = command_args.value_of("filename").unwrap();
            let img = get_image(&mut spi, verbose, dummy)?;
            let mut file = File::create(file)
                .map_err(|e| format!("Cannot create image file `{}': {}", file, e))?;
            img.save(&mut file, image::PNG)?;
            Ok(())
        }

        ("read_framebuffer_column", Some(command_args)) => {
            let column: u8 = command_args.value_of("column").unwrap().parse::<u8>()?;
            select_framebuffer_column(&mut spi, column, verbose, dummy)?;
            let fb_data = read_framebuffer_column(&mut spi, verbose, dummy)?;
            println!("Framebuffer data for column {}", column);
            println!("{:48b}", fb_data);
            Ok(())
        }

        (name, _) => {
            if let Some(command) = SpiCommand::decode(name) {
                transfer(&mut spi, command, &[], verbose, dummy).map(|_| ())
            } else {
                Ok(())
            }
        }
    }
}

fn create_spi(spi_dev: &str, freq: u32, configure: bool, verbose: bool) -> errors::Result<Spidev> {
    if verbose {
        println!(
            "Opening SPI device {} at {}bps{}",
            spi_dev,
            units::display(freq),
            if configure { "" } else { " (dummy mode)" }
        );
    }
    let mut spi =
        Spidev::open(spi_dev).map_err(|e| format!("Cannot open SPI device `{}': {}", spi_dev, e))?;

    let spi_options = SpidevOptions::new()
        .bits_per_word(8)
        .max_speed_hz(freq)
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

fn send_binary_file(
    spi: &mut Spidev,
    command: &SpiCommand,
    file: &str,
    payload_size: usize,
    verbose: bool,
    dummy: bool,
) -> errors::Result<()> {
    let mut file =
        File::open(file).map_err(|e| format!("Cannot open data file `{}': {}", file, e))?;

    let mut data = String::new();
    file.read_to_string(&mut data)?;
    let data = data.trim();
    let mut transaction = vec![0; payload_size];
    for i in 0..payload_size.min(data.len() / 8) {
        let word = &data[i * 8..(i + 1) * 8];
        transaction[i] = u8::from_str_radix(&word, 2)?;
    }
    transfer(spi, command, &transaction, verbose, dummy)?;
    Ok(())
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
