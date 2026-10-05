#!/usr/bin/env bash
# Battery as plain text; turns red under 20%, "+" while charging.

source "$HOME/.config/sketchybar/variables.sh"

BATT="$(pmset -g batt)"
PERCENTAGE="$(echo "$BATT" | grep -Eo "[0-9]+%" | cut -d% -f1)"
[ -z "$PERCENTAGE" ] && exit 0

COLOR="$COMMENT"
[ "$PERCENTAGE" -lt 20 ] && COLOR="$RED"
CHARGE=""
echo "$BATT" | grep -q "AC Power" && CHARGE="+"

sketchybar --set "$NAME" label="${PERCENTAGE}%${CHARGE}" label.color="$COLOR"
