# Tests for the SpiROSE renderer

display=10

function EXE {
    Xvfb :$display -screen 0 1280x720x24 +extension GLX &
    sleep 2
    DISPLAY=:$display XDG_RUNTIME_DIR=/tmp ./rose-renderer-poc $@ &
    sleep 5
}

function clean {
    echo "Removing artefacts"
    rm -rf tests/grab.png tests/sphere.png tests/monkey_noxor.png tests/monkey_xor.png
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
EXE -x -p

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

echo Start the renderer in non-xor mode
EXE -p -t 0
screenshot -page "1280x460" -crop "1280x460" "+repage"  tests/monkey_noxor.png
killApplication
echo Start the renderer in xor-mode
EXE -p -t 0 -x
screenshot -page "1280x460" -crop "1280x460" "+repage" tests/monkey_xor.png
killApplication

compare_out=`compare -metric AE "tests/monkey_xor.png" "tests/monkey_noxor.png" tests/monkey_xornoxor_difference.png 2>&1`
echo "AE: $compare_out"
if [[ $compare_out == "0" ]]; then
    echo The xor and no-xor methods are doing the same voxelization
else 
    echo The xor and no-xor methods are differents, see tests/monkey_xornoxor_difference.png
fi
