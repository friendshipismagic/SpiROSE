# Tests for the SpiROSE renderer

# Start the renderer just to know if the shaders are loaded
Xvfb :1 -screen 0 1280x720x24 +extension GLX &
DISPLAY=:1 XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc -x &
sleep 5
kill %2
kill %1

