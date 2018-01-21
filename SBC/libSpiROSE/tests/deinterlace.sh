#!/bin/bash

print_usage() {
echo "deinterlace.sh - Converts a linearized image to a readable form with an array"
echo "                 of microblocks"
echo "USAGE: ./deinterlace.sh <file> <to>"
echo "    from: source interlaced file"
echo "    to: output deinterlaced file"
}

if [[ "$#" != "2" || "$1" == "--help" ]]; then
    print_usage
    exit 0
fi

from=${1%.*}
ext=${1##*.}

# Generate ublocks
for block in {0..127}; do
	files=""
	for line in {0..47}; do
		x=$(($line * 40 % 640))
		y=$(($block * 3 + $line / 16))
		files="$files $1[40x1+$x+$y]"
	done
	montage $files -geometry +0+0 -background transparent -tile 1x48 $from-block-$block.$ext
done

# Generate ublock list in the proper order
files=""
for line in {0..7}; do
	for col in {0..15}; do
		files="$files $from-block-$(((7 - $line) * 16 + $col)).$ext"
	done
done

# Assemble blocks
montage $files -geometry +0+0 -background transparent -tile 16x8 $2

# Cleanup
rm -f $from-block-{0..127}.$ext

