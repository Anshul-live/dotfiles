#!/usr/bin/env bash

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

sketchybar --add event aerospace_workspace_change

sketchybar --add item spacer.1 left \
	--set spacer.1 \
	background.drawing=off \
	label.drawing=off \
	icon.drawing=off \
	width=10

for i in {1..10}; do
	sketchybar --add item space.$i left \
		--set space.$i \
		icon="${SPACE_ICONS[$((i-1))]}" \
		label.drawing=off \
		icon.padding_left=8 \
		icon.padding_right=8 \
		background.padding_left=3 \
		background.padding_right=3 \
		background.corner_radius="$CORNER_RADIUS" \
		background.height=20 \
		background.color="$BAR_COLOR" \
		background.border_width="$BORDER_WIDTH" \
		background.border_color="$RED" \
		click_script="aerospace workspace $i" \
		script="$PLUGIN_DIR/space.sh" \
		--subscribe space.$i aerospace_workspace_change
done
sketchybar --add bracket spaces '/space\..*/' \
	--set spaces \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$RED" \
	background.corner_radius="$CORNER_RADIUS" \
	background.color="$BAR_COLOR" \
	background.height=26 \
	background.drawing=on

sketchybar --trigger aerospace_workspace_change
