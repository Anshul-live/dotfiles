#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

CURRENT="${NAME#space.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [ "$CURRENT" = "$FOCUSED" ]; then
	sketchybar --set "$NAME" drawing=on icon.color="$WHITE" icon.font="$FONT:Bold:13.0"
elif aerospace list-workspaces --monitor all --empty no | grep -qx "$CURRENT"; then
	sketchybar --set "$NAME" drawing=on icon.color="$COMMENT" icon.font="$FONT:Regular:13.0"
else
	sketchybar --set "$NAME" drawing=off
fi
