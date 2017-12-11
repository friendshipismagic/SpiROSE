# Tests for the SpiROSE renderer

# Start the renderer just to know if the shaders are loaded
cd ../
./rose-renderer-poc -x &
pid=$!
kill -9 $pid

