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
brew "uv"                # Python CLI tools install.sh adds: qutebrowser, stig, apy

# terminal apps that replace GUI ones (workspace in brackets, see aerospace.toml)
brew "yazi"              # files (Finder): `y`
brew "poppler"           # yazi PDF previews
brew "ffmpeg"            # yazi video thumbnails
brew "btop"              # processes (Activity Monitor)
brew "libqalculate"      # calculator: qalc
brew "ouch"              # archives: ouch d file.zip (The Unarchiver)
brew "mpv"               # every video, YouTube via yt-dlp (IINA, VLC, QuickTime)
brew "yt-dlp"
brew "spotify_player"    # music [M] (Spotify; needs Premium)
brew "aerc"              # mail [C] (Gmail over IMAP)
brew "w3m"               # aerc's HTML mail filter
brew "khal"              # calendar [C]
brew "vdirsyncer"        # syncs Google Calendar for khal
brew "newsboat"          # RSS / articles [C]
brew "rbw"               # Bitwarden passwords (qutebrowser fills from it)
brew "transmission-cli"  # torrents (daemon; stig is the TUI)
brew "colima"            # headless Docker engine (Docker Desktop)
brew "docker"
brew "docker-compose"

# macOS only: window manager, bar, GUI apps, fonts
if OS.mac?
  tap "nikitabobko/tap"
  tap "felixkratz/formulae"
  brew "felixkratz/formulae/sketchybar"  # menu bar (workspaces, WINDOW mode badge)
  brew "felixkratz/formulae/borders"     # outline on the focused window
  brew "pinentry-mac"                    # rbw's password prompt
  cask "karabiner-elements"              # Caps: tap Esc / hold Ctrl; Right Cmd: Hyper (karabiner/)
  cask "raycast"                         # clipboard history, snippets, calculator, app launch
  # Qt for building sioyek (PDFs, workspace R; its cask was pulled, see sioyek/build.sh)
  brew "qtbase"
  brew "qtdeclarative"
  brew "qtsvg"
  brew "qtspeech"
  cask "drawio"                          # system design: drag-and-drop HLD/LLD diagrams (workspace D)
  cask "nikitabobko/tap/aerospace"       # tiling window manager
  cask "ghostty"
  cask "kitty"
  cask "font-jetbrains-mono-nerd-font"
end
