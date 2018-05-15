use commands::*;
use image::{DynamicImage, GenericImageView, Pixel as ImgPixel};

use super::*;
use std::fmt;

#[derive(Clone, Debug)]
pub struct Pixel {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

#[derive(Debug)]
pub struct FramebufferColumn(Vec<u8>);

impl fmt::Binary for FramebufferColumn {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        for led in 0..16 {
            write!(
                f,
                "{:b}:{:b}:{:b}",
                self.0[3 * led],
                self.0[3 * led + 1],
                self.0[3 * led + 2]
            )?;
            if led != 15 {
                write!(f, ", ")?;
            }
        }
        Ok(())
    }
}

impl From<image::Rgb<u8>> for Pixel {
    fn from(d: image::Rgb<u8>) -> Pixel {
        Pixel {
            r: d.data[0],
            g: d.data[1],
            b: d.data[2],
        }
    }
}

fn manage(spi: &mut Spidev, verbose: bool, dummy: bool) -> errors::Result<()> {
    transfer(spi, &MANAGE, &[], verbose, dummy).map(|_| ())
}

fn release(spi: &mut Spidev, verbose: bool, dummy: bool) -> errors::Result<()> {
    transfer(spi, &RELEASE, &[], verbose, dummy).map(|_| ())
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
    let answer = transfer(spi, &READ_PIXEL, &[block, offset], verbose, dummy)?;
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
        &WRITE_PIXEL,
        &[block, offset, p.b, p.g, p.r],
        verbose,
        dummy,
    ).map(|_| ())
}

pub fn send_image(
    spi: &mut Spidev,
    img: &DynamicImage,
    verbose: bool,
    dummy: bool,
) -> errors::Result<()> {
    if img.dimensions() != (40, 48) {
        return Err(format!(
            "Image dimension should be (40, 48), but is {:?} instead",
            img.dimensions()
        ).into());
    }
    manage(spi, verbose, dummy)?;
    for x in 0..40 {
        for y in 0..48 {
            let p = img.get_pixel(x, y).to_rgb().into();
            write_single_pixel(spi, x as u8, y as u8, &p, verbose, dummy)?;
        }
    }
    release(spi, verbose, dummy)
}

pub fn get_image(spi: &mut Spidev, verbose: bool, dummy: bool) -> errors::Result<DynamicImage> {
    manage(spi, verbose, dummy)?;
    let mut imgbuf = image::ImageBuffer::new(40, 48);
    for (x, y, pixel) in imgbuf.enumerate_pixels_mut() {
        let p = read_single_pixel(spi, x as u8, y as u8, verbose, dummy)?;
        *pixel = image::Rgb([p.r, p.g, p.b]);
    }
    release(spi, verbose, dummy)?;
    Ok(image::ImageRgb8(imgbuf))
}

fn block_offset(x: u8, y: u8) -> (u8, u8) {
    let block = 5 * (y / 16) + (x % 40) / 8;
    let offset = (y % 16) * 8 + (x % 8);
    (block, offset)
}

/// Select the column to profile for other framebuffer read commands
/// Return the last profiled column
pub fn select_framebuffer_column(
    spi: &mut Spidev,
    column: u8,
    verbose: bool,
    dummy: bool,
) -> errors::Result<u8> {
    transfer(spi, &SELECT_FRAMEBUFFER_COLUMN, &[column], verbose, dummy).map(|r| r[0])
}

pub fn read_framebuffer_column(
    spi: &mut Spidev,
    verbose: bool,
    dummy: bool,
) -> errors::Result<FramebufferColumn> {
    transfer(spi, &READ_FRAMEBUFFER_COLUMN, &[], verbose, dummy).map(FramebufferColumn)
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
