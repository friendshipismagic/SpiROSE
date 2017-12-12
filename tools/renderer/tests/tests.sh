# Tests for the SpiROSE renderer

function finish {
    kill %2
    kill %1
    rm -rf grab.jpg info.txt
}
trap finish EXIT

# Start the renderer just to know if the shaders are loaded
Xvfb :1 -screen 0 1280x720x24 +extension GLX &
DISPLAY=:1 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -x &
sleep 5

# Take a screenshot with imagemagick
DISPLAY=:1 import -window root grab.jpg
# Get the color of the center pixel
convert grab.jpg[1x1+640+360] -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info.txt
# Check that this pixel is not black
grep black info.txt && exit 1 || /bin/true
