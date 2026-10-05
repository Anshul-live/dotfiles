#!/usr/bin/env bash
# Set up these dotfiles on macOS or Linux. Safe to re-run.
#   ./install.sh           # install the tools (Homebrew + Brewfile + uv tools), apply macOS
#                          # defaults, link the configs
#   ./install.sh --links   # only link the configs
#   ./install.sh --macos   # only apply macOS system defaults (macos/defaults.sh)
# Links: correct links are left alone, anything else already at a target is moved
# to <target>.pre-dotfiles first.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

# --- packages ------------------------------------------------------------------
# Linux: what Homebrew needs to build/run, plus zsh itself (system one, so chsh accepts it)
linux_prereqs() {
  local sudo=""; [[ $EUID -ne 0 ]] && sudo="sudo"
  if command -v apt-get >/dev/null; then
    $sudo apt-get update -q
    $sudo apt-get install -y -q build-essential procps curl file git zsh
  elif command -v dnf >/dev/null; then
    $sudo dnf install -y -q @development-tools procps-ng curl file git zsh
  elif command -v pacman >/dev/null; then
    $sudo pacman -S --needed --noconfirm base-devel procps-ng curl file git zsh
  elif command -v zypper >/dev/null; then
    $sudo zypper install -y -t pattern devel_basis && $sudo zypper install -y procps curl file git zsh
  else
    echo "unknown package manager: install build tools, curl, file, git and zsh yourself" >&2
  fi
}

brew_env() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [[ -x $b ]] && { eval "$("$b" shellenv)"; return 0; }
  done
  return 1
}

install_packages() {
  [[ $OS == Linux ]] && linux_prereqs
  if ! brew_env; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_env
  fi
  brew bundle --file "$D/Brewfile"

  # Python apps, isolated by uv. qutebrowser's cask is gone (not notarized), PyPI has it;
  # adblock powers its request blocker. stig breaks on urwid 3+.
  [[ $OS == Darwin ]] && uv tool install -q qutebrowser --with PyQt6 --with PyQt6-WebEngine --with adblock
  uv tool install -q stig --with 'urwid>=2.6.12,<3'
  uv tool install -q apyanki

  # sioyek's cask is gone too (not notarized): build it into ~/Applications
  [[ $OS == Darwin ]] && "$D/sioyek/build.sh"
  [[ $OS == Darwin ]] && "$D/macos/defaults.sh"

  # login shell -> zsh (macOS already defaults to it)
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ $OS == Linux && "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path" || echo "couldn't change shell; run: chsh -s $zsh_path" >&2
  fi
}

if [[ ${1:-} == --macos ]]; then "$D/macos/defaults.sh"; exit 0; fi
[[ ${1:-} == --links ]] || install_packages

# --- links ---------------------------------------------------------------------
link() {
  local src="$D/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok     $dst"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.pre-dotfiles"
    echo "moved  $dst -> $dst.pre-dotfiles"
  fi
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

link nvim                 "$HOME/.config/nvim"
link kitty/kitty.conf     "$HOME/.config/kitty/kitty.conf"
link ghostty/config       "$HOME/.config/ghostty/config"
link tmux/tmux.conf       "$HOME/.config/tmux/tmux.conf"
link starship/starship.toml "$HOME/.config/starship.toml"
link zsh/zshenv             "$HOME/.zshenv"
# also here: shells that inherit ZDOTDIR (tmux panes, nvim :terminal) read this one
link zsh/zshenv             "$HOME/.config/zsh/.zshenv"
link zsh/zshrc              "$HOME/.config/zsh/.zshrc"
link zsh/zprofile           "$HOME/.config/zsh/.zprofile"
link bin/tmux-sessionizer "$HOME/.local/bin/tmux-sessionizer"
link bin/ws-session       "$HOME/.local/bin/ws-session"
link bin/cp-fetch         "$HOME/.local/bin/cp-fetch"
link bin/cards            "$HOME/.local/bin/cards"
link bin/block            "$HOME/.local/bin/block"
link bin/qb               "$HOME/.local/bin/qb"

# terminal apps
link yazi                 "$HOME/.config/yazi"
link btop                 "$HOME/.config/btop"
link spotify_player       "$HOME/.config/spotify-player"
link khal/config          "$HOME/.config/khal/config"
link vdirsyncer/config    "$HOME/.config/vdirsyncer/config"
link newsboat/config      "$HOME/.config/newsboat/config"
link newsboat/urls        "$HOME/.config/newsboat/urls"
mkdir -p "$HOME/.local/share/newsboat" # its cache dir in XDG mode
link stig                 "$HOME/.config/stig"
link mpv/mpv.conf         "$HOME/.config/mpv/mpv.conf"
link mpv/input.conf       "$HOME/.config/mpv/input.conf"
# aerc reads ~/Library/Preferences/aerc on macOS (no XDG_CONFIG_HOME here)
if [[ $OS == Darwin ]]; then AERC="$HOME/Library/Preferences/aerc"; else AERC="$HOME/.config/aerc"; fi
link aerc/aerc.conf       "$AERC/aerc.conf"
link aerc/binds.conf      "$AERC/binds.conf"
link aerc/stylesets       "$AERC/stylesets"
# aerc refuses an accounts.conf that isn't mode 600, which git can't keep: copy it once
# (no secrets in it, passwords come from rbw)
[[ -e "$AERC/accounts.conf" ]] || { install -m 600 "$D/aerc/accounts.conf.example" "$AERC/accounts.conf" && echo "copied $AERC/accounts.conf"; }

if [[ $OS == Darwin ]]; then
  link aerospace/aerospace.toml "$HOME/.config/aerospace/aerospace.toml"
  link aerospace/setup.sh      "$HOME/.config/aerospace/setup.sh"
  link sketchybar            "$HOME/.config/sketchybar"
  link borders               "$HOME/.config/borders"
  link karabiner/karabiner.json "$HOME/.config/karabiner/karabiner.json"
  # qutebrowser writes quickmarks/bookmarks into ~/.qutebrowser, so link files, not the dir
  link qutebrowser/config.py    "$HOME/.qutebrowser/config.py"
  link qutebrowser/userscripts  "$HOME/.qutebrowser/userscripts"
  link qutebrowser/greasemonkey "$HOME/.qutebrowser/greasemonkey"
  link sioyek/prefs_user.config "$HOME/.config/sioyek/prefs_user.config"
  link sioyek/keys_user.config  "$HOME/.config/sioyek/keys_user.config"
  # launchd can skip symlinked agents at login: copy (started by hand once Google is set up)
  cp "$D/vdirsyncer/com.anshul.vdirsyncer.plist" "$HOME/Library/LaunchAgents/"

  echo
  echo "distraction blocker (once, needs your password):  sudo $D/blocker/install.sh"
fi
