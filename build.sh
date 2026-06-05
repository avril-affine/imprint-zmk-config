#!/usr/bin/env bash


on_error() {
    set +x
    while [ $(dirs | wc -w) -gt 1 ]; do
        popd
    done
    exit 1
}

trap "on_error" ERR
set -x

if ! command -v uv; then
    echo 'uv is not installed'
    exit 1
fi

if [ ! -d "zmk/zephyr" ]; then
    pushd zmk
    west init -l app/
    popd
fi

if [ ! -d "zmk/modules" ]; then
    pushd zmk
    west update
    west zephyr-export
    popd
fi

SCRIPT_DIR=$(dirname $(readlink -f $0))
APP_DIR="${SCRIPT_DIR}/zmk/app"
CONFIG_DIR="${SCRIPT_DIR}/config"
EXTRA_MODULES="${SCRIPT_DIR}/zmk-keyboards;${SCRIPT_DIR}/zmk-pmw3610-driver"
OUT_DIR="${SCRIPT_DIR}/_build/$(date -Iseconds)"
LEFT_OUT="${OUT_DIR}/imprint_left.uf2"
RIGHT_OUT="${OUT_DIR}/imprint_right.uf2"

pushd $APP_DIR
echo $PWD
uv run west build -p -b assimilator-bt -d build/left -- \
    -DZMK_CONFIG=$CONFIG_DIR -DSHIELD=imprint_left \
    -DZMK_EXTRA_MODULES="$EXTRA_MODULES"
uv run west build -p -b assimilator-bt -d build/right -- \
    -DZMK_CONFIG=$CONFIG_DIR -DSHIELD=imprint_right \
    -DZMK_EXTRA_MODULES="$EXTRA_MODULES"
mkdir -p "$OUT_DIR"
cp build/left/zephyr/zmk.uf2 "$LEFT_OUT"
cp build/right/zephyr/zmk.uf2 "$RIGHT_OUT"
ln -sf "$LEFT_OUT" "${SCRIPT_DIR}/latest-left.uf2"
ln -sf "$RIGHT_OUT" "${SCRIPT_DIR}/latest-right.uf2"
popd
