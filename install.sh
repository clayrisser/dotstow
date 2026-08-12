#!/bin/sh

set -e

REPO="${REPO:-https://gitlab.com/bitspur/tools/dotstow.git}"

MAKE=make
if command -v gmake >/dev/null 2>&1; then
    MAKE=gmake
fi

_TMP_PATH=$(mktemp -d)
trap 'rm -rf "$_TMP_PATH"' EXIT

git clone "$REPO" "$_TMP_PATH/dotstow"
cd "$_TMP_PATH/dotstow"
$MAKE install
