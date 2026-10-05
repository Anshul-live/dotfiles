#!/usr/bin/env bash

MODE="$(aerospace list-modes --current)"
if [ "$MODE" = "main" ] || [ -z "$MODE" ]; then
	sketchybar --set "$NAME" drawing=off popup.drawing=off
else
	sketchybar --set "$NAME" drawing=on popup.drawing=on label="$(echo "$MODE" | tr '[:lower:]' '[:upper:]')"
fi
