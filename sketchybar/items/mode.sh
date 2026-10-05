#!/usr/bin/env bash
# AeroSpace mode badge: hidden normally, shows " WINDOW " while ctrl-alt-space mode is on
# (like the mode badge in the Neovim statusline). AeroSpace fires the event on every mode change.
# updates=on: the bar's default (when_shown) would never run the script while the badge is hidden.

sketchybar --add event aerospace_mode_change \
	--add item aerospace_mode left \
	--set aerospace_mode \
	drawing=off \
	updates=on \
	icon.drawing=off \
	label.color="$BLACK" \
	label.padding_left=8 \
	label.padding_right=8 \
	background.color="$RED" \
	background.corner_radius="$CORNER_RADIUS" \
	background.height=22 \
	script="$PLUGIN_DIR/mode.sh" \
	--subscribe aerospace_mode aerospace_mode_change
