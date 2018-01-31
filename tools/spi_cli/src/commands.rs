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
            "get_speed" => Some(&GET_SPEED),
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
        pub static $name: SpiCommand = SpiCommand { id: $id, recv_len: $recv_len };
    }
}

spi_command!(ENABLE_RGB, 0xe0);
spi_command!(DISABLE_RGB, 0xd0);
spi_command!(ENABLE_MUX, 0xe1, 1);
spi_command!(DISABLE_MUX, 0xd1, 1);
spi_command!(GET_ROTATION, 0x4c, 2);
spi_command!(GET_SPEED, 0x4d, 2);
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
