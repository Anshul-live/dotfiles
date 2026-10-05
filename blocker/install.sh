#!/usr/bin/env bash
# Install / update the distraction blocker. Run once with sudo; safe to re-run.
#   sudo ~/dotfiles/blocker/install.sh
# Puts the engine in /usr/local/libexec/blocker-apply, the state in
# /usr/local/etc/blocker/ and the daemon in /Library/LaunchDaemons, all root-owned
# so unblocking can't skip the 24h queue without sudo. The repo blocklist is only
# a seed: it's merged in (never removes anything, never re-adds a finished unblock).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
LABEL=com.anshul.blocker
PLIST=/Library/LaunchDaemons/$LABEL.plist
APPLY=/usr/local/libexec/blocker-apply
STATE=/usr/local/etc/blocker

[[ $(uname -s) == Darwin ]] || { echo "macOS only" >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo $0" >&2; exit 1; }

install -d -o root -g wheel -m 755 /usr/local/libexec "$STATE"
install -o root -g wheel -m 755 "$D/blocker-apply" "$APPLY"
for f in blocklist pending removed; do
  [[ -e $STATE/$f.txt ]] || install -o root -g wheel -m 644 /dev/null "$STATE/$f.txt"
done
"$APPLY" seed "$D/blocklist.txt"

install -o root -g wheel -m 644 "$D/$LABEL.plist" "$PLIST"
launchctl bootout "system/$LABEL" 2>/dev/null || true
launchctl enable "system/$LABEL"
# bootstrap straight after bootout can fail with EIO while the old job winds down
for i in 1 2 3 4 5; do
  launchctl bootstrap system "$PLIST" 2>/dev/null && break
  [[ $i == 5 ]] && { echo "launchctl bootstrap failed" >&2; exit 1; }
  sleep 1
done
echo "daemon loaded: $LABEL"

"$APPLY" apply
echo "done: $(sed -n '/^# >>> blocker >>>$/,/^# <<< blocker <<<$/p' /etc/hosts | grep -c '^0\.0\.0\.0 ' || true) hostnames blocked in /etc/hosts"
echo "restart open browsers so they drop live connections to blocked sites"
