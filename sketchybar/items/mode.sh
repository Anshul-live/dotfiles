#!/usr/bin/env bash
# AeroSpace mode badge: hidden normally, shows " WINDOW " while ctrl-alt-space mode is on
# (like the mode badge in the Neovim statusline), with a cheat-sheet popup underneath.
# AeroSpace fires the event on every mode change.
# updates=on: the bar's default (when_shown) would never run the script while the badge is hidden.

sketchybar --add event aerospace_mode_change \
	--add item aerospace_mode left \
	--set aerospace_mode \
	drawing=off \
	updates=on \
	icon.drawing=off \
	label.color="$BLACK" \
	label.font="$FONT:Bold:11.0" \
	label.padding_left=6 \
	label.padding_right=6 \
	background.drawing=on \
	background.padding_left=8 \
	background.color="$RED" \
	background.corner_radius="$CORNER_RADIUS" \
	background.height=18 \
	popup.align=left \
	popup.y_offset=6 \
	script="$PLUGIN_DIR/mode.sh" \
	--subscribe aerospace_mode aerospace_mode_change

# key | action, one popup row each (keep in sync with aerospace/aerospace.toml)
HELP=(
	"d s v m e|setup: dev / study / video / comms / design"
	"h j k l|focus window"
	"H J K L|move window"
	"ctrl-h j k l|join with neighbour (split)"
	"-  =|shrink / grow"
	"f|fullscreen"
	"/|side-by-side tiles (default; flip)"
	",|full-screen stack"
	"t|float <-> tile"
	"r|reset layout"
	"x|close window"
	"c|reload config"
	"esc|back to normal"
	"⌃⌥ T B N C V M D|go to workspace (no mode needed)"
)
i=0
for row in "${HELP[@]}"; do
	sketchybar --add item "aerospace_mode.help.$i" popup.aerospace_mode \
		--set "aerospace_mode.help.$i" \
		icon="${row%%|*}" \
		icon.color="$YELLOW" \
		icon.width=120 \
		icon.padding_left=12 \
		icon.font="$FONT:Regular:12.0" \
		label="${row#*|}" \
		label.padding_right=12 \
		padding_left=0 \
		background.height=22
	i=$((i + 1))
done
