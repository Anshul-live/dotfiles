#!/usr/bin/env bash
# Workspace names as plain text: focused is bright, ones with windows are dim, empty ones hidden.
# updates=on: hidden items would otherwise never get the event that shows them again.

sketchybar --add event aerospace_workspace_change

# same order as persistent-workspaces in aerospace.toml
for i in T B N C V M 1 2 3; do
	sketchybar --add item space.$i left \
		--set space.$i \
		icon="$i" \
		updates=on \
		icon.padding_left=6 \
		icon.padding_right=6 \
		label.drawing=off \
		click_script="aerospace workspace $i" \
		script="$PLUGIN_DIR/space.sh" \
		--subscribe space.$i aerospace_workspace_change front_app_switched
done

sketchybar --trigger aerospace_workspace_change
