# Tests for the SpiROSE renderer

function finish {
    kill %2
    wait %2 2> /dev/null
    kill %1
    wait %1 1> /dev/null
}
trap finish EXIT

echo Start the renderer
Xvfb :10 -screen 0 1280x720x24 +extension GLX &
sleep 1
DISPLAY=:10 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -x -p&
echo Wait for the shaders to load...
sleep 5

# Take a screenshot with imagemagick
DISPLAY=:10 import -window root tests/grab.png
if [[ ! -f tests/grab.png ]]; then
    echo "Screenshot hasn't been captured"
    exit 1
fi

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
kill %2
wait %2 2> /dev/null
sleep 1

# Start the renderer with a sphere and pause it at 5 second
echo Start the renderer with a sphere
DISPLAY=:10 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -m mesh/sphere.obj -t 5 -p &
echo Wait for the shaders to load...
sleep 5
# Take a screenshot with imagemagick
DISPLAY=:10 import -window root tests/sphere.png
compare_out=`compare -metric AE tests/sphere.png tests/sphere_reference.png tests/sphere_difference.png 2>&1`
echo "AE: $compare_out"
if [[ $compare_out == "0" ]]; then
    echo The sphere is correctly voxelized
else
    echo The sphere rendering has changed since the previous snapshot, see tests/sphere_difference.png
    exit 1
fi

