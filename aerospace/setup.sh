#!/usr/bin/env bash
# Prewritten setups: open the apps for a task and spread them over workspaces.
# Run from AeroSpace WINDOW mode (ctrl-alt-space, then d / s / v / m), or by hand: setup.sh dev
#
#   dev    T Ghostty: pick a project -> tmux session (nvim + shell)   B Safari      ends on T
#   study  N Obsidian | Safari side by side   M Spotify (background)                ends on N
#   video  V DaVinci Resolve   M Spotify (background)                               ends on V
#   comms  C Mail, Calendar, Messages, WhatsApp                                     ends on C
#
# Safe to re-run: anything already in place is left alone, only missing windows are opened.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" # AeroSpace runs this without Homebrew on PATH

GHOSTTY=com.mitchellh.ghostty
SAFARI=com.apple.Safari
OBSIDIAN=md.obsidian
SPOTIFY=com.spotify.client
RESOLVE=com.blackmagic-design.DaVinciResolve
MAIL=com.apple.mail
CALENDAR=com.apple.iCal
MESSAGES=com.apple.MobileSMS
WHATSAPP=net.whatsapp.WhatsApp

# window ids of an app, optionally only on one workspace
wins() {
	if [ -n "${2:-}" ]; then
		aerospace list-windows --workspace "$2" --app-bundle-id "$1" --format '%{window-id}'
	else
		aerospace list-windows --monitor all --app-bundle-id "$1" --format '%{window-id}'
	fi
}

# wait (up to ~20s, apps like Resolve are slow) for a window of $1 that isn't in $2; print its id
wait_new() {
	local id
	for _ in $(seq 100); do
		id=$(comm -13 <(printf '%s\n' "$2" | sort) <(wins "$1" | sort) | head -1)
		[ -n "$id" ] && echo "$id" && return 0
		sleep 0.2
	done
	return 1
}

# make sure workspace $2 has a window of app $1: keep one already there, else move one over,
# else open the app ($3 = how to open it; default `open -b`)
place() {
	local app=$1 ws=$2 id before
	[ -n "$(wins "$app" "$ws")" ] && return 0
	id=$(wins "$app" | head -1)
	if [ -z "$id" ]; then
		before=$(wins "$app")
		${3:-open -b "$app"}
		id=$(wait_new "$app" "$before") || return 1
	fi
	aerospace move-node-to-workspace --window-id "$id" "$ws" >/dev/null
}

# like place, but always a NEW window (so the one on its home workspace stays put)
place_new() {
	local app=$1 ws=$2 id before
	[ -n "$(wins "$app" "$ws")" ] && return 0
	before=$(wins "$app")
	$3
	id=$(wait_new "$app" "$before") || return 1
	aerospace move-node-to-workspace --window-id "$id" "$ws" >/dev/null
}

# Ghostty window running the project picker; drops to a shell if you detach
ghostty_project() {
	pgrep -xq ghostty || { open -b $GHOSTTY && sleep 1; }
	osascript -e 'tell application "Ghostty" to new window with configuration {command:"/bin/zsh -lc \"$HOME/.local/bin/tmux-sessionizer; exec zsh -l\""}' >/dev/null
}
safari_window() {
	pgrep -xq Safari || { open -b $SAFARI && sleep 1; }
	osascript -e 'tell application "Safari" to make new document' >/dev/null
}
spotify_bg() { open -gb $SPOTIFY; } # -g: start without stealing focus

# lay workspace $1 out side by side, $2's window on the left
side_by_side() {
	local left
	left=$(wins "$2" "$1" | head -1)
	[ -z "$left" ] && return
	aerospace layout --window-id "$left" h_tiles
	aerospace move --window-id "$left" --boundaries workspace --boundaries-action stop left 2>/dev/null
}

case "${1:-}" in
dev)
	place_new $GHOSTTY T ghostty_project
	place $SAFARI B
	aerospace workspace T
	;;
study)
	place $OBSIDIAN N
	place_new $SAFARI N safari_window
	side_by_side N $OBSIDIAN
	place $SPOTIFY M spotify_bg
	aerospace workspace N
	;;
video)
	place $RESOLVE V
	place $SPOTIFY M spotify_bg
	aerospace workspace V
	;;
comms)
	for app in $MAIL $CALENDAR $MESSAGES $WHATSAPP; do place $app C; done
	aerospace workspace C
	;;
*)
	echo "usage: $(basename "$0") dev|study|video|comms" >&2
	exit 1
	;;
esac
