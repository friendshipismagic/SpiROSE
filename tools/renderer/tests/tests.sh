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
# Tests for the SpiROSE renderer

display=10

function EXE {
    Xvfb :$display -screen 0 1280x720x24 +extension GLX &
    sleep 5
    DISPLAY=:$display XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc $@ &
    sleep 10
}

function clean {
    echo "Removing artefacts"
    pushd tests
    rm -rf grab.png \
           sphere{_difference,}.png \
           monkey_{gl,gles,gles_difference}.png \
           text_{gl,gles}{_gs,}_t{0,5}{_difference,}.png
    popd
}

function finish {
    killApplication
}

function screenshot {
    DISPLAY=:$display import -window root $@
    if [[ ! -f ${*: -1:1} ]]; then
        echo "Screenshot hasn't been captured"
        exit 1
    fi

}

function cropInterlace {
    convert $1[640x384+640+336] $1
}

function killApplication {
    kill %2 2> /dev/null
    wait %2 2> /dev/null
    kill %1 2> /dev/null
    wait %1 2> /dev/null
    display=$(($display + 1))
}

trap finish EXIT

clean

echo Start the renderer
EXE -p

screenshot tests/grab.png

# Get the color of the center pixel
pixel=`convert "tests/grab.png[1x1+600+360]" -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info:- || exit 1`
echo "Pixel informations : $pixel"
# Check that this pixel is not black
if [[ "$pixel" == "0,0,0" ]]; then
    echo The renderer has a black pixel at 600x360, see grab.png
    exit 1
else
    echo The renderer starts properly and displays something
fi
killApplication

echo

echo Start the renderer with a sphere
EXE -m mesh/sphere.obj -t 5 -p
screenshot tests/sphere.png
killApplication
compare_out=`compare -metric AE tests/sphere.png tests/sphere_reference.png tests/sphere_difference.png 2>&1`
echo "AE: $compare_out"
if [[ $compare_out == "0" ]]; then
    echo The sphere is correctly voxelized
else
    echo The sphere rendering has changed since the previous snapshot, see tests/sphere_difference.png
    exit 1
fi

echo

echo Start the renderer with text mesh
EXE -pt 0 -m mesh/text.obj
screenshot tests/text_gl_gs_t0.png
cropInterlace tests/text_gl_gs_t0.png
killApplication
EXE -pt 5 -m mesh/text.obj
screenshot tests/text_gl_gs_t5.png
cropInterlace tests/text_gl_gs_t5.png
killApplication
compare_out=$(compare -metric AE tests/text_gl_gs_t0.png tests/text_t0_ref.png tests/text_gl_t0_difference.png 2>&1)
compare_out_t5=$(compare -metric AE tests/text_gl_gs_t5.png tests/text_t5_ref.png tests/text_gl_t5_difference.png 2>&1)
echo AE: t0: $compare_out, t5: $compare_out_t5
if [[ $compare_out == "0" ]] && [[ $compare_out_t5 == "0" ]]; then
    echo Output is correctly interlaced
else
    echo The interlace has changed since the previous snapshot, see tests/text_gl_t0_difference.png and tests/text_gl_t5_difference.png
    exit 1
fi

echo

echo Rebuild the renderer without geometry shaders
make clean
make NO_GEOMETRY_SHADER=yes

echo

echo Start the renderer with the monkey
EXE -p -t 0
screenshot tests/monkey_gl.png
killApplication

echo Start the renderer with text mesh
EXE -pt 0 -m mesh/text.obj
screenshot tests/text_gl_t0.png
cropInterlace tests/text_gl_t0.png
killApplication
EXE -pt 5 -m mesh/text.obj
screenshot tests/text_gl_t5.png
cropInterlace tests/text_gl_t5.png
killApplication

compare_out=$(compare -metric AE tests/text_gl_gs_t0.png tests/text_gl_t0.png tests/text_gl_t0_difference.png 2>&1)
compare_out_t5=$(compare -metric AE tests/text_gl_gs_t5.png tests/text_gl_t5.png tests/text_gl_t5_difference.png 2>&1)
echo AE: t0: $compare_out, t5: $compare_out_t5
if [[ $compare_out == "0" ]] && [[ $compare_out_t5 == "0" ]]; then
    echo Interlace output is the same with and without geometry shaders
else
    echo Interlace output is different with and without geometry shaders, see tests/text_gl_t0_difference.png and tests/text_gl_t5_difference.png
    exit 1
fi

echo

echo Recompile in GLES mode
make clean
make UNAME_P=armv7l || exit 1

echo

echo Start the renderer with the monkey
EXE -p -t 0
screenshot tests/monkey_gles.png
killApplication

echo Start the renderer with text mesh
EXE -pt 0 -m mesh/text.obj
screenshot tests/text_gles_t0.png
cropInterlace tests/text_gles_t0.png
killApplication
EXE -pt 5 -m mesh/text.obj
screenshot tests/text_gles_t5.png
cropInterlace tests/text_gles_t5.png
killApplication

compare_out=`compare -metric AE "tests/monkey_gl.png" "tests/monkey_gles.png" tests/monkey_gles_difference.png 2>&1`
echo "AE: $compare_out"
if [[ $compare_out == "0" ]]; then
    echo The GLES and GL methods are doing the same voxelization
else
    echo The GLES and GL methods are differents, see tests/monkey_gles_difference.png
    exit 1
fi

compare_out=$(compare -metric AE tests/text_gl_gs_t0.png tests/text_gles_t0.png tests/text_gles_t0_difference.png 2>&1)
compare_out_t5=$(compare -metric AE tests/text_gl_gs_t5.png tests/text_gles_t5.png tests/text_gles_t5_difference.png 2>&1)
echo AE: t0: $compare_out, t5: $compare_out_t5
if [[ $compare_out == "0" ]] && [[ $compare_out_t5 == "0" ]]; then
    echo Interlace output is the same both in GL and GLES
else
    echo Interlace output is different between GL and GLES, see tests/text_gl_t0_difference.png and tests/text_gl_t5_difference.png
    exit 1
fi

killApplication
