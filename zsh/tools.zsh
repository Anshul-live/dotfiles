# fzf: ctrl-r history, ctrl-t files (bat preview), alt-c dirs (tree preview)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
source <(fzf --zsh)

# after fzf: fzf --zsh binds <tab> too, and fzf-tab has to win
# fzf-tab: <tab> menu with the same colours/flags as every other fzf; < > switch groups; previews
source $ZPLUGINS/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z|eza|ls):*' fzf-preview 'eza -1 --icons --color=always --group-directories-first $realpath'
zstyle ':fzf-tab:complete:(nvim|v|bat|cat):*' fzf-preview '[[ -f $realpath ]] && bat --color=always --style=numbers --line-range=:100 $realpath || eza -1 --icons --color=always $realpath'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -o pid,%cpu,%mem,command -p $word'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always -- $realpath'

eval "$(zoxide init zsh)" # z <part of dir>, zi to pick

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100
source $ZPLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZPLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

eval "$(starship init zsh)"
