#!/usr/bin/env bash
# Set up these dotfiles on macOS or Linux. Safe to re-run.
#   ./install.sh           # install the tools (Homebrew + Brewfile), link the configs
#   ./install.sh --links   # only link the configs
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

  # login shell -> zsh (macOS already defaults to it)
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ $OS == Linux && "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path" || echo "couldn't change shell; run: chsh -s $zsh_path" >&2
  fi
}

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
link bin/tmux-sessionizer "$HOME/.local/bin/tmux-sessionizer"

if [[ $OS == Darwin ]]; then
  link aerospace/aerospace.toml "$HOME/.config/aerospace/aerospace.toml"
  link aerospace/setup.sh      "$HOME/.config/aerospace/setup.sh"
  link sketchybar            "$HOME/.config/sketchybar"
  link borders               "$HOME/.config/borders"
fi
