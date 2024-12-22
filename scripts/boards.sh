#!/bin/sh

BOARD="$1"
SESSION_PID=$(pstree -aps | head -n 1 | cut -d, -f2)
BUILD_MEMO="/tmp/thingino-board.$SESSION_PID"

log() {
	echo "$1" > /dev/stderr
}

save_memo() {
	log "Save $CAMERA_CONFIG to $BUILD_MEMO"
	echo "$CAMERA_CONFIG" > "$BUILD_MEMO"
}

delete_memo() {
	log "Delete $BUILD_MEMO"
	rm "$BUILD_MEMO"
}

check_memo() {
	log "Check saved config"

	if [ -f "$BUILD_MEMO" ]; then
		log "File $BUILD_MEMO found"
	else
		log "File $BUILD_MEMO not found"
		return
	fi

	CAMERA_CONFIG=$(cat "$BUILD_MEMO")
	log "CAMERA_CONFIG=$CAMERA_CONFIG"

	if [ -z "$CAMERA_CONFIG" ]; then
		log "CAMERA_CONFIG is empty"
		delete_memo
		return
	fi

	if whiptail --yesno "Use $CAMERA_CONFIG from the previous session?" 20 76 3>&1 1>&2 2>&3 ; then
		log "Use $CAMERA_CONFIG"
		save_memo
		echo "$CAMERA_CONFIG"
		exit 0
	else
		log "Do not use $CAMERA_CONFIG"
		unset CAMERA_CONFIG
		delete_memo
	fi
}

log "--------------------------------------------------------------------------------------------------- BOARDS.SH"

if [ -z "$BOARD" ]; then
	log "BOARD is empty"
	check_memo
else
	log "BOARD=$BOARD"

	log "Search camera config"
	CAMERA_CONFIG="$(find ./configs/modules ./configs/cameras ./configs/github ./configs/testing -name "$BOARD" | sed 's/\.\/configs\///')"
fi

if [ -z "$CAMERA_CONFIG" ]; then
	log "Camera config not found"

	log "Read list of cameras"

	CAMERAS=$(grep 'NAME:' ./configs/*_defconfig | awk -F'[/:]' '{print $3,"\""substr($5,2,100)"\""}')
	CAMERA_CONFIG=$(whiptail --title \"Config files\" --menu \"Select a config\" 20 76 12 --notags $CAMERAS 3>&1 1>&2 2>&3)

	echo "CAMERA_CONFIG=$CAMERA_CONFIG"

#	log "Select a camera config"
#	whiptail --title "Config files" --menu "Select a config" 20 76 12 --notags \
#		$(grep NAME: ./configs/*_defconfig | awk -F'[/:]' '{print "\""$3"\" \""$5"\""}')

#		#CAMERA_CONFIG= 3>&1 1>&2 2>&3)
#		"$NOCAMERA" "*----- BARE MODULES ----------------------*" $MODULES \
#		"$NOCAMERA" "*----- EXPERIMENTS -----------------------*" $TESTING \
	exit

	if [ "$CAMERA_CONFIG" = "$NOCAMERA" ]; then
		log "Operation cancelled"
		exit 1
	fi
fi


CAMERA_CONFIG_REAL=$(realpath ./configs/$CAMERA_CONFIG)
echo "$CAMERA_CONFIG_REAL"
exit 0
