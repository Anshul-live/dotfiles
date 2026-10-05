#!/usr/bin/env bash

sketchybar --add item battery right \
	--set battery \
	update_freq=120 \
	icon.drawing=off \
	label.color="$COMMENT" \
	label.padding_right=16 \
	script="$PLUGIN_DIR/power.sh" \
	--subscribe battery power_source_change system_woke
