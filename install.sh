#!/usr/bin/env bash
# Link these dotfiles into place. Safe to re-run: correct links are left alone,
# anything else already at a target is moved to <target>.pre-dotfiles first.
#   brew bundle            # install the tools (see Brewfile)
#   ./install.sh           # link the configs
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"

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
link bin/tmux-sessionizer "$HOME/.local/bin/tmux-sessionizer"
