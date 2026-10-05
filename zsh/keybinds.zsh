bindkey -e # emacs keys (ctrl-a/e/w/u...); Neovim is for modal editing

# ↑ / ↓ (and ctrl-p / ctrl-n): history entries starting with what's typed so far
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search '^[OA' up-line-or-beginning-search '^P' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search '^N' down-line-or-beginning-search

# alt-← / alt-→ by word (Ghostty sends Option as Alt); ctrl-w stops at / and .
bindkey '^[[1;3D' backward-word '^[[1;3C' forward-word
WORDCHARS=${WORDCHARS//[\/.]}

bindkey '^[[Z' reverse-menu-complete # shift-tab

# ctrl-x ctrl-e: edit the command line in Neovim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^ ' autosuggest-accept # ctrl-space takes the grey suggestion
