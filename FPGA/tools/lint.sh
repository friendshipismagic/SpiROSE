#!/bin/sh

LINTER="verilator"
LINTER_ARGS="--lint-only -Wall verilator.vlt"

function on_exit() {
	cp src/.ram_backed_do_not_use.v src/ram.v
	rm src/.ram_backed_do_not_use.v
}

trap on_exit EXIT

cp src/ram.v src/.ram_backed_do_not_use.v
cp src/ram_stub.v src/ram.v
$LINTER $LINTER_ARGS $1 -y src

exit $?
