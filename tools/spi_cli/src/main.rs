extern crate clap;
use clap::App;

fn main() {
    App::new("SPI ROSE Command Line Tool")
        .version("0.1.0")
        .about("Yet Another CLI for SPI matching the SpiROSE SPI behaviour")
        .get_matches();
}
