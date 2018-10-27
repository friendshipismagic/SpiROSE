// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#[derive(Clone, Debug)]
pub struct SpiCommand {
    pub id: u8,
    pub recv_len: usize,
}

impl SpiCommand {
    pub fn decode(command: &str) -> Option<&'static SpiCommand> {
        match command {
            "enable_rgb" => Some(&ENABLE_RGB),
            "disable_rgb" => Some(&DISABLE_RGB),
            "get_rotation" => Some(&GET_ROTATION),
            "get_config" => Some(&GET_CONFIG),
            "get_debug" => Some(&GET_DEBUG),
            "manage" => Some(&MANAGE),
            "release" => Some(&RELEASE),
            "reset" => Some(&RESET),
            _ => None,
        }
    }
}

macro_rules! spi_command {
    ($name:ident, $id:expr) => {
        spi_command!($name, $id, 0);
    };
    ($name:ident, $id:expr, $recv_len:expr) => {
        pub static $name: SpiCommand = SpiCommand {
            id: $id,
            recv_len: $recv_len,
        };
    };
}

spi_command!(ENABLE_RGB, 0xe0);
spi_command!(DISABLE_RGB, 0xd0);
spi_command!(ENABLE_MUX, 0xe1, 1);
spi_command!(DISABLE_MUX, 0xd1, 1);
spi_command!(GET_ROTATION, 0x4c, 2);
spi_command!(GET_SPEED, 0x4d, 4);
spi_command!(GET_CONFIG, 0xbf, 6);
spi_command!(GET_DEBUG, 0xde, 4);
spi_command!(SEND_DRIVER_RGB, 0xee, 48);
spi_command!(SEND_DRIVER_POKERED, 0xef, 54);
spi_command!(MANAGE, 0xfa);
spi_command!(RELEASE, 0xfe);
spi_command!(RESET, 0xa0);
spi_command!(READ_PIXEL, 0x20, 3);
spi_command!(WRITE_PIXEL, 0x21);
spi_command!(SELECT_FRAMEBUFFER_COLUMN, 0x24, 1);
spi_command!(READ_FRAMEBUFFER_COLUMN, 0x25, 48);
