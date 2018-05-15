#!/bin/bash
#
# Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
# Alexandre Janniaux, Adrien Marcenat
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

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

