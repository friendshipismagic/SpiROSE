#[macro_use]
extern crate clap;
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

#[cfg(test)]
mod test;

// LEDDriverConfig is the struct containing the LED Driver Config
// The serialized version is 48b long
// As we send MSB for each packet, but LSB
#[derive(Debug, Deserialize, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct LEDDriverConfig {
    #[packed_field(bits = "46..47")] lodvth: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "44..45")] sel_td0: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "43")] sel_gdly: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "42")] xrefresh: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "41")] sel_gck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "40")] sel_pchg: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "39")] espwm: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "38")] lgse3: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "37")] sel_sck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "34..36")] lgse1: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "25..33", endian="msb")] ccb: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "16..24", endian="msb")] ccg: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "7..15", endian="msb")] ccr: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "4..6")] bc: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "3")] poker_trans_mode: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "0..2")] lgse2: Integer<u8, ::packed_bits::Bits3>,
}

#[derive(Debug)]
struct SpiCommand {
    id: u8,
    recv_len: usize,
}

impl SpiCommand {

    fn enable_rgb() -> SpiCommand { SpiCommand { id: 0xE0, recv_len: 0 } }

    fn disable_rgb() -> SpiCommand { SpiCommand { id: 0xD0, recv_len: 0 } }

    fn blink_led() -> SpiCommand { SpiCommand { id: 0xDE, recv_len: 0 } }

    fn rotation() -> SpiCommand { SpiCommand { id: 0x4C, recv_len: 1 } }

    fn config() -> SpiCommand { SpiCommand { id: 0xBF, recv_len: 6 } }

    fn decode(command : &str) -> Option<SpiCommand> {
        match command {
            "enable_rgb" => Some(SpiCommand::enable_rgb()),
            "disable_rgb" => Some(SpiCommand::disable_rgb()),
            "blink_led" => Some(SpiCommand::blink_led()),
            "rotation" => Some(SpiCommand::rotation()),
            "config" => Some(SpiCommand::config()),
            _ => None,
        }
    }
}

fn main() {
    let yaml_cli_config = load_yaml!("cli.yml");
    let matches = App::from_yaml(yaml_cli_config).get_matches();

    let spi_dev = matches.value_of("device").unwrap();
    let dummy = spi_dev == "none";
    let mut spi = create_spi(if dummy { "/dev/null" } else { spi_dev }, !dummy).unwrap();
    if let Some(command_args) = matches.subcommand_matches("send") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = SpiCommand::decode(command).expect("Command not recognized");
        send(&mut spi, &decoded_command, &[]).unwrap();
    } else if let Some(command_args) = matches.subcommand_matches("get") {
        let command = command_args.value_of("command").unwrap();
        let decoded_command = SpiCommand::decode(command).expect("Command not recognized");
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
        let serialized_conf = led_config.pack();
        println!("Serialized conf: {:?}", serialized_conf);
        send(&mut spi, &SpiCommand::decode("config").unwrap(), &serialized_conf).unwrap();
    }
}

fn create_spi(spi_dev: &str, configure: bool) -> io::Result<Spidev> {
    let mut spi = Spidev::open(spi_dev)?;

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


fn send<T : Write+Read>(spi: &mut T, command: &SpiCommand, command_args: &[u8]) -> io::Result<()> {
    spi.write_all(&[command.id])?;

    // Send optionnal arguments with the command (for instance, configuration data)
    if !command_args.is_empty() {
        spi.write_all(command_args)?;
    }

    Ok(())
}

fn get<T : Write+Read>(spi: &mut T, command: &SpiCommand, command_args: &[u8]) -> io::Result<Vec<u8>> {
    send(spi, command, command_args)?;
    let mut read_vec = vec![0; command.recv_len];
    spi.read_exact(&mut read_vec)?;

    Ok(read_vec)
}
