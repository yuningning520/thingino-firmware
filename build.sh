#!/bin/bash
#
# Thingino Firmware build script
# (c) 2024 Thingino Project
#

die() {
	echo "$1" > /dev/stderr
	exit 1
}

select_profile() {
	profiles=()

	IFS=$'\n' read -r -d '' -a profiles < \
	<(grep 'NAME:' ./configs/$1/* | sed -E "s/\.\/configs\/$1\/(.+):#\s*NAME:\s*(.+)$/\1\n\2/" && printf '\0')

	CAMERA_CONFIG=$(whiptail --backtitle "Thingino Firmware" --title "Select camera configuration" \
		--menu "Please select a profile to build" 20 76 12 --notags "${profiles[@]}" \
		3>&1 1>&2 2>&3)
}

CAMERA_CATEGORY="cameras"
case "$1" in
	modules)
		CAMERA_CATEGORY="modules"
		;;
	testing)
		CAMERA_CATEGORY="testing"
		;;
	help)
		die "Usage: $0 [camera_config] [buildroot_options]"
		;;
	*)
		# read camera config from the command line
		# CAMERA_CONFIG="$1"
		true
		;;
esac

# if not provided, ask user to select one
[ -z "$CAMERA_CONFIG" ] && select_profile "$CAMERA_CATEGORY"

# if still not provided, exit
[ -z "$CAMERA_CONFIG" ] && die "\$CAMERA_CONFIG is empty!"

# check if the camera config exists
[ -f "./configs/$CAMERA_CATEGORY/$CAMERA_CONFIG" ] || die "Camera config not found!"

# prepare camera defconfig file name
CAMERA_DEFCONFIG="${CAMERA_CONFIG}_defconfig"

# create output directory
OUTPUT_DIR="$HOME/output/$CAMERA_CONFIG"
mkdir -p "$OUTPUT_DIR"

# prepare full camera defconfig file
BUILD_CONFIG="./configs/$CAMERA_DEFCONFIG"
:> "$BUILD_CONFIG"

# append camera config
[ -f "./configs/cameras/$CAMERA_CONFIG" ] && \
	cat "./configs/cameras/$CAMERA_CONFIG" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"

# append modules
MODULE_CONFIG=$(awk '/MODULE:/ {$1=$1;gsub(/^.+:\s*/,"");print}' "$BUILD_CONFIG")
[ -z "$MODULE_CONFIG" ] || \
	cat "./configs/modules/$MODULE_CONFIG" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"

# append fragments
for i in $(awk '/FRAG:/ {$1=$1;gsub(/^.+:\s*/,"");print}' "$BUILD_CONFIG"); do
	cat "./configs/fragments/$i.fragment" >> "$BUILD_CONFIG"
	echo >> "$BUILD_CONFIG"
done

# append local configuration
[ -f local.fragment ] && cat local.fragment >> "$BUILD_CONFIG"

# copy local.mk to output directory
[ -f local.mk ] && cp -f local.mk "$OUTPUT_DIR/local.mk"

# create symlink to the project root
[ -L "$OUTPUT_DIR/thingino" ] || ln -sr "$(pwd)" "$OUTPUT_DIR/thingino"

# create buildroot make command
BR_MAKE="make V=1 -C $PWD/buildroot BR2_EXTERNAL=$PWD O=$OUTPUT_DIR"

# provision for custom buildroot configuration
$BR_MAKE "$CAMERA_DEFCONFIG"

# run buildroot
$BR_MAKE "$@"

echo "Done"
exit 0