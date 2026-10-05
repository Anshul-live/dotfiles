#!/usr/bin/env bash
# Prewritten setups: open the apps for a task and spread them over workspaces.
# Run from AeroSpace WINDOW mode (hyper-space, then d / s / v / m / e), or by hand: setup.sh dev
#
#   dev    T Ghostty: pick a project -> tmux session   B qutebrowser                ends on T
#   study  N notes   B qutebrowser   M music (spotify_player, in the background)    ends on N
#   video  V DaVinci Resolve   M music (in the background)                         ends on V
#   comms  C Ghostty comms session (aerc, khal, newsboat) + Messages + WhatsApp    ends on C
#   design D draw.io | Excalidraw (qutebrowser) side by side                       ends on D
#
#   ensure B|N|C|M   if that workspace is empty, open what lives there (Hyper+B/N/C/M run this
#                    right after switching, so a workspace is never empty when you land on it)
#
# The terminal workspaces are tmux sessions (~/.local/bin/ws-session): closing the window
# loses nothing, the next visit re-attaches.
# Safe to re-run: anything already in place is left alone, only missing windows are opened.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" # AeroSpace runs this without Homebrew on PATH

GHOSTTY=com.mitchellh.ghostty
QUTE=qutebrowser # not a bundle id, see wins()
RESOLVE=com.blackmagic-design.DaVinciResolve
MESSAGES=com.apple.MobileSMS
WHATSAPP=net.whatsapp.WhatsApp
DRAWIO=com.jgraph.drawio.desktop

# window ids of an app, optionally only on one workspace
# (qutebrowser is a pip install without an app bundle: its windows are found by the
# title suffix config.py pins, see qutebrowser/config.py window.title_format)
wins() {
	local scope=(--monitor all)
	[ -n "${2:-}" ] && scope=(--workspace "$2")
	if [ "$1" = "$QUTE" ]; then
		aerospace list-windows "${scope[@]}" --format '%{window-id}|%{window-title}' |
			awk -F'|' '/qutebrowser$/ { print $1 }'
	else
		aerospace list-windows "${scope[@]}" --app-bundle-id "$1" --format '%{window-id}'
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
ghostty_project() { ghostty_run '$HOME/.local/bin/tmux-sessionizer'; }
# Ghostty window attached to a workspace session (notes / comms / music)
ghostty_session() { ghostty_run "\$HOME/.local/bin/ws-session $1"; }
ghostty_run() {
	pgrep -xq ghostty || { open -b $GHOSTTY && sleep 1; }
	osascript -e "tell application \"Ghostty\" to new window with configuration {command:\"/bin/zsh -lc \\\"$1; exec zsh -l\\\"\"}" >/dev/null
}
# qutebrowser (uv tool, no .app) opens new windows through its running instance (--target window)
qute_window() {
	nohup "$HOME/.local/bin/qutebrowser" --target window "${1:-about:blank}" >/dev/null 2>&1 &
}
excalidraw_window() { qute_window https://excalidraw.com; }
# music plays from a detached tmux session; a window is only needed to look at it
music_bg() { "$HOME/.local/bin/ws-session" music -d; }

# lay workspace $1 out side by side, $2's window on the left
side_by_side() {
	local left
	left=$(wins "$2" "$1" | head -1)
	[ -z "$left" ] && return
	aerospace layout --window-id "$left" h_tiles
	# list-windows is in layout order: swap until $2's window is first (leftmost)
	for _ in 1 2 3; do
		[ "$(aerospace list-windows --workspace "$1" --format '%{window-id}' | head -1)" = "$left" ] && break
		aerospace swap --window-id "$left" left 2>/dev/null
	done
}

# a fresh Ghostty window for session $2 on workspace $1, focused if you're still there
session_on() {
	place_new $GHOSTTY "$1" "ghostty_session $2" || return
	[ "$(aerospace list-workspaces --focused)" = "$1" ] &&
		aerospace focus --window-id "$(wins $GHOSTTY "$1" | head -1)"
}

# ensure: only acts on an empty workspace; the lock stops a double press opening two windows
ensure() {
	[ -n "$(aerospace list-windows --workspace "$1" --format '%{window-id}')" ] && return 0
	mkdir "${TMPDIR:-/tmp}/aerospace-ensure-$1" 2>/dev/null || return 0
	trap 'rmdir "${TMPDIR:-/tmp}/aerospace-ensure-$1"' EXIT
	case $1 in
	B) place_new $QUTE B qute_window ;;
	N) session_on N notes ;;
	C) session_on C comms ;;
	M) session_on M music ;;
	esac
}

case "${1:-}" in
dev)
	place_new $GHOSTTY T ghostty_project
	ensure B
	aerospace workspace T
	;;
study)
	ensure N
	ensure B
	music_bg
	aerospace workspace N
	;;
video)
	place $RESOLVE V
	music_bg
	aerospace workspace V
	;;
comms)
	ensure C
	for app in $MESSAGES $WHATSAPP; do place $app C; done
	aerospace workspace C
	;;
design)
	place $DRAWIO D
	place_new $QUTE D excalidraw_window
	side_by_side D $DRAWIO
	aerospace workspace D
	;;
ensure)
	ensure "${2:-}"
	;;
*)
	echo "usage: $(basename "$0") dev|study|video|comms|design|ensure B|N|C|M" >&2
	exit 1
	;;
esac
