#!/usr/bin/env sh

# Color Palette: vague, the same colours as Neovim, Ghostty and tmux
# (values from vague.nvim's get_palette(); keep the names so the item scripts don't change)
BLACK=0xff141415     # bg
WHITE=0xffcdcdcd     # fg
MAGENTA=0xffbb9dbd   # parameter
BLUE=0xff6e94b2      # keyword
CYAN=0xffaeaed1      # constant
GREEN=0xff7fa563     # plus
YELLOW=0xfff3be7c    # warning
ORANGE=0xffe0a363    # number
RED=0xffd8647e       # error
COMMENT=0xff606079   # comment
LINE=0xff252530      # line (raised surfaces: popups)
BAR_COLOR=$BLACK     # same as the terminal background, so the bar reads as part of the screen

TRANSPARENT=0x00000000

# General bar colors
ICON_COLOR=$WHITE  # Color of all icons
LABEL_COLOR=$WHITE # Color of all labels

ITEM_DIR="$HOME/.config/sketchybar/items"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

FONT="JetBrainsMono Nerd Font"

PADDINGS=3

POPUP_BORDER_WIDTH=2
POPUP_CORNER_RADIUS=11
POPUP_BACKGROUND_COLOR=$LINE
POPUP_BORDER_COLOR=$COMMENT

CORNER_RADIUS=6
BORDER_WIDTH=2

SHADOW=off
