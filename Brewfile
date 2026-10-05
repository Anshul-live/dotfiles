# brew bundle  -> installs everything this setup uses (install.sh runs it, macOS and Linux)
brew "neovim"
brew "tree-sitter-cli"   # nvim-treesitter compiles parsers with it
brew "ripgrep"           # grep in pickers
brew "fd"                # file finding in pickers
brew "fzf"               # tmux-sessionizer, ctrl-r/ctrl-t, fzf-tab
brew "tmux"
brew "lazygit"           # git mode (<space>g) then L
brew "lazydocker"        # <space>od
brew "hurl"              # REST client (*.hurl files)
brew "jq"                # formats JSON responses
brew "cmake"             # C/C++ projects (:CMakeGen, build & debug)
brew "node"              # JS/TS tooling, npm-based language servers
brew "go"
brew "starship"          # zsh prompt
brew "eza"               # ls
brew "bat"               # cat, fzf previews
brew "zoxide"            # z <part of dir>

# macOS only: window manager, bar, GUI apps, fonts
if OS.mac?
  tap "nikitabobko/tap"
  tap "felixkratz/formulae"
  brew "felixkratz/formulae/sketchybar"  # menu bar (workspaces, WINDOW mode badge)
  brew "felixkratz/formulae/borders"     # outline on the focused window
  cask "drawio"                          # system design: drag-and-drop HLD/LLD diagrams (workspace D)
  cask "nikitabobko/tap/aerospace"       # tiling window manager
  cask "ghostty"
  cask "kitty"
  cask "font-jetbrains-mono-nerd-font"
end
