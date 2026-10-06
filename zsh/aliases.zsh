alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons --git-ignore"
alias cat="bat --style=plain"     # pages only when longer than the screen

alias v="nvim"
alias c="clear"
alias reload="exec zsh"
alias ..="cd .."
alias ...="cd ../.."

alias gs="git status -sb"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph -20"
alias gd="git diff"

alias grep="grep --color=auto"
alias mysql="mysql --system-command=on"

# ── apps by what they do ── (`tools` lists every line below that ends in a # comment)
alias mail="aerc"                        # mail (aerc)
alias inbox="matcha"                     # mail, threaded split view (matcha)
alias cal="ikhal"                        # calendar (ikhal); `command cal` for the old one
alias agenda="khal list today 7d"        # next 7 days of events
alias news="newsboat"                    # RSS feeds and articles
alias music="spotify_player"             # Spotify
alias play="mpv"                         # play a video file or URL
alias pdf="sioyek"                       # read a PDF
alias top="btop"                         # processes
alias torrents="stig"                    # torrents (transmission)
alias calc="qalc"                        # calculator with units: calc 5 GiB to MB
alias unpack="ouch decompress"           # extract any archive
alias pack="ouch compress"               # pack files: pack dir out.tar.gz
alias lg="lazygit"                       # git UI
alias dk="lazydocker"                    # docker UI
alias web="qb"                           # open a URL in qutebrowser
alias pass="rbw get"                     # password from Bitwarden: pass 'Gmail app password'
alias review="cards review"              # flashcards due today
alias focus="block"                      # distraction blocker: focus add x.com
alias notes="cd ~/Documents/Devlogs && nvim"  # Obsidian vault in nvim
alias dots="cd ~/dotfiles"               # this repo

# ── competitive programming ──
alias dsa="cd ~/Desktop/code/dsa"        # solutions repo
alias solve="cp-fetch"                   # solve <problem url>: fetch it and open nvim
alias leet="lc"                          # leetgo: leet test 1 -L, leet submit 1
alias pick="nvim +'lua require(\"config.cp\").pick()'"       # pick a LeetCode problem in nvim
alias solutions="nvim +'lua require(\"config.cp\").browse()'"  # browse your solutions in nvim

# tools: the cheat sheet of the aliases above (name, then what it does)
tools() {
  awk -F'#' '
    /^# ── / { on = 1; sub(/^# ── /, ""); sub(/ ──.*/, ""); printf "\n\033[1m%s\033[0m\n", $0; next }
    on && /^(alias [^=]+=|[a-z]+\(\)).*#/ {
      name = $1; sub(/^alias /, "", name); sub(/[=(].*/, "", name)
      desc = $NF; sub(/^ +/, "", desc)
      printf "  \033[36m%-10s\033[0m %s\n", name, desc
    }' "$ZSH_DIR/aliases.zsh"
  echo
}

# ── files ──
y() {                                    # files (yazi); on quit, cd to where you were
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n $cwd && $cwd != $PWD && -d $cwd ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
