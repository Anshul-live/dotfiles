# vi mode, like everything else: Esc (tap Caps) for normal mode, then hjkl, w/b/e, 0/$, x,
# dd, cw, ciw, u, p, / and n to search history, v to edit the line in Neovim, i/a/A back.
# The cursor shows the mode (block = normal, beam = insert); the prompt arrow flips to ❮.
bindkey -v
KEYTIMEOUT=1 # Esc switches at once instead of waiting 0.4s for a key sequence

# insert mode keeps the few emacs keys worth having: ctrl-a/e line start/end, ctrl-w word,
# ctrl-u line; backspace deletes past where insert started (vi's own stops there)
bindkey -M viins '^A' beginning-of-line '^E' end-of-line
bindkey -M viins '^W' backward-kill-word '^U' backward-kill-line
bindkey -M viins '^?' backward-delete-char '^H' backward-delete-char

# ↑ / ↓ (and ctrl-p / ctrl-n), k / j in normal mode: history entries starting with what's typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search '^[OA' up-line-or-beginning-search '^P' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search '^N' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search 'j' down-line-or-beginning-search

# alt-← / alt-→ by word (Ghostty sends Option as Alt); ctrl-w stops at / and .
bindkey '^[[1;3D' backward-word '^[[1;3C' forward-word
WORDCHARS=${WORDCHARS//[\/.]}

bindkey '^[[Z' reverse-menu-complete # shift-tab

# v in normal mode (or ctrl-x ctrl-e): edit the command line in Neovim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^ ' autosuggest-accept # ctrl-space takes the grey suggestion

# cursor shape per mode. Defined before starship's init (tools.zsh), which wraps
# zle-keymap-select to redraw its vi-mode prompt symbol and still calls this one.
_cursor_for_keymap() { [[ $KEYMAP == vicmd ]] && printf '\e[2 q' || printf '\e[6 q'; }
zle-keymap-select() { _cursor_for_keymap; }
zle-line-init() { printf '\e[6 q'; } # every new prompt starts in insert mode
zle -N zle-keymap-select
zle -N zle-line-init
# programs started from the shell (nvim sets its own) get the block cursor back
_cursor_block() { printf '\e[2 q'; }
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cursor_block
