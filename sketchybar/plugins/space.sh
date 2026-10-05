#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

CURRENT="${NAME#space.}"
FOCUSED="$(aerospace list-workspaces --focused)"

if [ "$CURRENT" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    icon.color="$RED"
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color="$COMMENT"
fi
