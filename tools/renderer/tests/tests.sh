# Tests for the SpiROSE renderer

function finish {
    kill %2
    kill %1
    rm -rf grab.jpg info.txt
}
trap finish EXIT

echo Start the renderer
Xvfb :1 -screen 0 1280x720x24 +extension GLX &
DISPLAY=:1 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -x &
echo Wait for the shaders to load...
sleep 5

# Take a screenshot with imagemagick
DISPLAY=:1 import -window root grab.jpg
# Get the color of the center pixel
convert grab.jpg[1x1+640+360] -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info.txt
# Check that this pixel is not black
grep black info.txt && exit 1 || /bin/true
echo The renderer starts properly and displays something
kill %2
sleep 1

# Start the renderer with a sphere and pause it at 5 second
echo Start the renderer with a sphere
DISPLAY=:1 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -m mesh/sphere.obj -t 5 -p &
echo Wait for the shaders to load...
sleep 5
# Take a screenshot with imagemagick
DISPLAY=:1 import -window root tests/sphere.jpg
compare_out=`compare -metric PSNR tests/sphere.jpg tests/sphere_reference.jpg tests/sphere_difference.jpg 2>&1`
if [[ $compare_out == "0" ]]; then
    echo The sphere is correctly voxelized
else
    echo The sphere rendering has changed since the previous snapshot, see tests/sphere_difference.jpg
    exit 1
fi

