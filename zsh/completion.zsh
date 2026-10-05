# Completion. The cache is rebuilt (with the security check) at most once a day;
# other starts reuse it, which saves ~30ms.
ZCOMPDUMP=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
[[ -d ${ZCOMPDUMP:h} ]] || mkdir -p ${ZCOMPDUMP:h}
autoload -Uz compinit
if [[ -n $ZCOMPDUMP(#qN.mh+24) || ! -f $ZCOMPDUMP ]]; then
  compinit -d $ZCOMPDUMP
else
  compinit -C -d $ZCOMPDUMP
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' # any case; f.b<tab> -> foo.bar
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${ZCOMPDUMP:h}/cache
zstyle ':completion:*' ignored-patterns '*.o' '*.pyc' '*.class'
zstyle ':completion:*' menu no # fzf-tab draws the menu
