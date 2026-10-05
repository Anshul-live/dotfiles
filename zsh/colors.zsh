# Shell tool colours in vague, the same as Neovim, Ghostty, tmux and sketchybar.
# Sourced from zshrc. eza and fast-syntax-highlighting use the terminal's
# 16 colours, which Ghostty already sets to vague.

# fzf (ctrl-r, ctrl-t, alt-c, and the tmux project picker)
export FZF_DEFAULT_OPTS="--layout=reverse --border=sharp --info=inline \
  --color=bg:#141415,bg+:#252530,fg:#cdcdcd,fg+:#cdcdcd,hl:#6e94b2,hl+:#6e94b2 \
  --color=border:#606079,prompt:#6e94b2,pointer:#6e94b2,marker:#7fa563,info:#606079,spinner:#606079,header:#606079"

# bat (cat): use the terminal palette instead of its own theme
export BAT_THEME="ansi"

# zsh-autosuggestions: the grey suggestion text is vague's comment colour
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#606079"

# ls / eza / completion colours from the terminal's 16 (vague) colours: dirs blue, links
# purple, executables green
export LS_COLORS="di=34:ln=35:so=33:pi=33:ex=32:bd=33:cd=33:su=31:sg=31:tw=34:ow=34"
