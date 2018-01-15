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
use toml::Value;
use packed_struct::prelude::*;

// LEDDriverConfig is the struct containing the LED Driver Config
// The serialized version is 48b long
#[derive(Debug, Deserialize, PackedStruct)]
#[packed_struct(bit_numbering = "msb0")]
pub struct LEDDriverConfig {
    #[packed_field(bits = "0..1")] lodvth: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "2..3")] sel_td0: Integer<u8, ::packed_bits::Bits2>,
    #[packed_field(bits = "4")] sel_gdly: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "5")] xrefresh: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "6")] sel_gck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "7")] sel_pchg: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "8")] espwm: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "9")] lgse3: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "10")] sel_sck_edge: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "11..13")] lgse1: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "14..22", endian="msb")] ccb: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "23..31", endian="msb")] ccg: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "32..40", endian="msb")] ccr: Integer<u16, ::packed_bits::Bits9>,
    #[packed_field(bits = "41..43")] bc: Integer<u8, ::packed_bits::Bits3>,
    #[packed_field(bits = "44")] poker_trans_mode: Integer<u8, ::packed_bits::Bits1>,
    #[packed_field(bits = "45..47")] lgse2: Integer<u8, ::packed_bits::Bits3>,
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
        let serialized_conf = led_config.pack();
        println!("Serialized conf: {:?}", serialized_conf);
        send(&mut spi, &decode_command("config").unwrap(), &serialized_conf);
    }
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
        "rgb_enable" => Some(SpiCommand {
            id: 0xE0,
            recv_len: 0,
        }),
        "rgb_disable" => Some(SpiCommand {
            id: 0xD0,
            recv_len: 0,
        }),
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
