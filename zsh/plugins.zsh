# Plugins: plain shallow git clones, sourced directly. No plugin manager, so startup stays
# a few ms. Missing ones are cloned on first start; `zsh-update` pulls them all.
ZPLUGINS=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
_zplugins=(
  zsh-users/zsh-completions          # extra completions (brew, docker, cargo, ...)
  Aloxaf/fzf-tab                     # <tab> completion in an fzf menu with previews
  zsh-users/zsh-autosuggestions      # grey suggestion from history; → accepts
  zdharma-continuum/fast-syntax-highlighting
)
for _p in $_zplugins; do
  [[ -d $ZPLUGINS/${_p:t} ]] || git clone --depth 1 -q https://github.com/$_p $ZPLUGINS/${_p:t}
done
unset _p
fpath=($ZPLUGINS/zsh-completions/src $HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

zsh-update() {
  local d
  for d in $ZPLUGINS/*(/); do print -P "%F{8}${d:t}%f"; git -C $d pull -q --ff-only; done
  rm -f $ZCOMPDUMP && exec zsh
}
