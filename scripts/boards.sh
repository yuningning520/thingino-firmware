#!/bin/sh

BOARD="$1"
SESSION_PID=$(pstree -aps | head -n 1 | cut -d, -f2)
BUILD_MEMO="/tmp/thingino-board.$SESSION_PID"

log() {
	echo "$1" > /dev/stderr
}

check_memo() {
	log "Check saved config"

	if [ ! -f "$BUILD_MEMO" ]; then
		log "File $BUILD_MEMO not found"
		return
	fi

	CAMERA_CONFIG=$(cat "$BUILD_MEMO")
	if [ -z "$CAMERA_CONFIG" ]; then
		log "Delete $BUILD_MEMO"
		rm "$BUILD_MEMO"
		return
	fi

	whiptail --yesno "Use $CAMERA_CONFIG from the previous session?" 20 76 3>&1 1>&2 2>&3 && return
       
	unset CAMERA_CONFIG
	log "Delete $BUILD_MEMO"
	rm "$BUILD_MEMO"
}

log "--------------------------------------------------------------------------------------------------- BOARDS.SH"

if [ -z "$BOARD" ]; then
	log "\$BOARD is empty"
	check_memo
else
	log "Search camera config for $BOARD"
	CAMERA_CONFIG="$(find ./configs/modules ./configs/cameras ./configs/github ./configs/testing -name "$BOARD" | sed 's/\.\/configs\///')"
fi

if [ -z "$CAMERA_CONFIG" ]; then
	log "Select a camera config"

	CAMERAS=$(find ./configs/cameras/* | sort | sed -E "s/^\.\/configs\/cameras\/(.*)/cameras\/\1 \1/")
	MODULES=$(find ./configs/modules/* | sort | sed -E "s/^\.\/configs\/modules\/(.*)/modules\/\1 \1/")
	TESTING=$(find ./configs/testing/* | sort | sed -E "s/^\.\/configs\/testing\/(.*)/testing\/\1 \1/")

	NOCAMERA=""
	CAMERA_CONFIG="$NOCAMERA"
	#while [ "$NOCAMERA" = "$CAMERA_CONFIG" ]; do
	CAMERA_CONFIG=$(whiptail --title "Config files" --menu "Select a config:" 20 76 12 --notags \
		"$NOCAMERA" "*----- CAMERAS ---------------------------*" $CAMERAS \
		"$NOCAMERA" "*----- BARE MODULES ----------------------*" $MODULES \
		"$NOCAMERA" "*----- EXPERIMENTS -----------------------*" $TESTING \
		3>&1 1>&2 2>&3)

	if [ "$CAMERA_CONFIG" = "$NOCAMERA" ]; then
		log "Cancel operation"
		exit 1
	fi
	#done
fi

log "Save camera config"
echo "$CAMERA_CONFIG" > "$BUILD_MEMO"
CAMERA=$(basename "$CAMERA_CONFIG")

echo "$CAMERA"
exit 0
