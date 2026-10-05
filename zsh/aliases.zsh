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
