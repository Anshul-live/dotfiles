#!/usr/bin/env bash

MODE="$(aerospace list-modes --current)"
if [ "$MODE" = "main" ] || [ -z "$MODE" ]; then
	sketchybar --set "$NAME" drawing=off
else
	sketchybar --set "$NAME" drawing=on label="$(echo "$MODE" | tr '[:lower:]' '[:upper:]')"
fi
