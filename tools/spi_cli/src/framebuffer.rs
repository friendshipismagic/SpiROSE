use image::{GenericImage, ImageBuffer};

use super::*;

static ReadPixel: SpiCommand = SpiCommand {
    id: 0x20,
    recv_len: 3,
};
static WritePixel: SpiCommand = SpiCommand {
    id: 0x21,
    recv_len: 0,
};

#[derive(Clone, Debug)]
pub struct Pixel {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

fn manage(spi: &mut Spidev, verbose: bool, dummy: bool) -> errors::Result<()> {
    transfer(spi, &Manage, &[], verbose, dummy).map(|_| ())
}

fn release(spi: &mut Spidev, verbose: bool, dummy: bool) -> errors::Result<()> {
    transfer(spi, &Release, &[], verbose, dummy).map(|_| ())
}

pub fn read_pixel(
    spi: &mut Spidev,
    x: u8,
    y: u8,
    verbose: bool,
    dummy: bool,
) -> errors::Result<Pixel> {
    manage(spi, verbose, dummy)?;
    let p = read_single_pixel(spi, x, y, verbose, dummy);
    release(spi, verbose, dummy)?;
    p
}

fn read_single_pixel(
    spi: &mut Spidev,
    x: u8,
    y: u8,
    verbose: bool,
    dummy: bool,
) -> errors::Result<Pixel> {
    let (block, offset) = block_offset(x, y);
    let answer = transfer(spi, &ReadPixel, &[block, offset], verbose, dummy)?;
    Ok(Pixel {
        r: answer[2],
        g: answer[1],
        b: answer[0],
    })
}

pub fn write_pixel(
    spi: &mut Spidev,
    x: u8,
    y: u8,
    p: &Pixel,
    verbose: bool,
    dummy: bool,
) -> errors::Result<()> {
    manage(spi, verbose, dummy)?;
    write_single_pixel(spi, x, y, p, verbose, dummy)?;
    release(spi, verbose, dummy)
}

pub fn color(spi: &mut Spidev, p: &Pixel, verbose: bool, dummy: bool) -> errors::Result<()> {
    manage(spi, verbose, dummy)?;
    for x in 0..40 {
        for y in 0..48 {
            write_single_pixel(spi, x, y, p, verbose, dummy)?;
        }
    }
    release(spi, verbose, dummy)
}

fn write_single_pixel(
    spi: &mut Spidev,
    x: u8,
    y: u8,
    p: &Pixel,
    verbose: bool,
    dummy: bool,
) -> errors::Result<()> {
    let (block, offset) = block_offset(x, y);
    transfer(
        spi,
        &WritePixel,
        &[block, offset, p.b, p.g, p.r],
        verbose,
        dummy,
    ).map(|_| ())
}

fn block_offset(x: u8, y: u8) -> (u8, u8) {
    let block = 5 * (y / 16) + (x % 40) / 8;
    let offset = (y % 16) * 8 + (x % 8);
    (block, offset)
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn coordinates_mapping() {
        assert_eq!(block_offset(0, 0), (0, 0));
        assert_eq!(block_offset(39, 0), (4, 7));
        assert_eq!(block_offset(0, 32), (10, 0));
        assert_eq!(block_offset(39, 32), (14, 7));
        assert_eq!(block_offset(39, 47), (14, 127));
    }

}
