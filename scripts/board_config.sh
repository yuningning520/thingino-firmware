#!/bin/bash

CAMERA="$1"

if [ -z "$CAMERA" ]; then
	echo "\$CAMERA is empty!"
	exit 1
fi

OUTPUT_DIR="$HOME/output/$CAMERA"
mkdir -p "$OUTPUT_DIR"

BUILD_CONFIG="$OUTPUT_DIR/.config"
:> "$BUILD_CONFIG"

CAMERA_CONFIG="$(find ./configs/modules ./configs/cameras ./configs/github ./configs/testing -name "$CAMERA" | head -n1 | sed 's/\.\/configs\///')"

[ -f "./configs/$CAMERA_CONFIG" ] && \
	cat "./configs/$CAMERA_CONFIG" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"

MODULE_CONFIG=$(awk '/MODULE:/ {$1=$1;gsub(/^.+:\s*/,"");print}' "$BUILD_CONFIG")
[ -z "$MODULE_CONFIG" ] || \
	cat "./configs/modules/$MODULE_CONFIG" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"

for i in $(awk '/FRAG:/ {$1=$1;gsub(/^.+:\s*/,"");print}' "$BUILD_CONFIG"); do
	cat "./configs/fragments/$i.fragment" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"
done

[ -f local.fragment ] && cat local.fragment >> "$BUILD_CONFIG"
[ -f local.mk       ] && cp -f local.mk "$OUTPUT_DIR/local.mk"

[ -L "$OUTPUT_DIR/thingino" ] || ln -sr $(pwd) "$OUTPUT_DIR/thingino"

exit 0