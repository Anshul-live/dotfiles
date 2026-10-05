# qutebrowser: the daily browser, as terminal-like as possible (keyboard only, vague colours,
# no chrome). install.sh links this file, userscripts/ and greasemonkey/ into ~/.qutebrowser/
# (qutebrowser's config dir on macOS). Chrome stays installed as the fallback (,o).
# :help, :bind and :set show every option/binding; reload this file with :config-source.
import re

from qutebrowser.api import interceptor
from qutebrowser.qt.core import QUrl

# Code only: settings changed with :set don't stick, so this file is the whole truth
config.load_autoconfig(False)

# Apps spawned from qutebrowser (launched from AeroSpace/Dock) get launchd's bare PATH,
# so external tools are referenced by full path
BREW = '/opt/homebrew/bin'
MPV = f'{BREW}/mpv --force-window=immediate'

# --- look -----------------------------------------------------------------------
bg, fg, line, sel, dim = '#141415', '#cdcdcd', '#252530', '#333738', '#606079'
red, green, yellow, orange = '#d8647e', '#7fa563', '#f3be7c', '#e0a363'
blue, magenta, cyan = '#6e94b2', '#bb9dbd', '#aeaed1'

c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '13pt'
c.fonts.web.family.fixed = 'JetBrainsMono Nerd Font'  # code blocks on docs pages
c.fonts.hints = 'bold default_size default_family'
# 13" screen: pages a notch bigger than 100%, still fits docs side by side with a terminal
c.zoom.default = '110%'

# No title bar: AeroSpace tiles the window (as with Ghostty)
c.window.hide_decoration = True
# Installed from PyPI, so the process is Python, not a qutebrowser.app: AeroSpace matches
# windows by this title suffix (the default, pinned here so it can't drift)
c.window.title_format = '{perc}{current_title}{title_sep}qutebrowser'
# Tabs only when there is more than one; no favicons, no indicator graphics
c.tabs.show = 'multiple'
c.tabs.position = 'top'
c.tabs.favicons.show = 'never'
c.tabs.indicator.width = 0
c.tabs.padding = {'top': 2, 'bottom': 2, 'left': 6, 'right': 6}
c.tabs.title.format = '{index} {audio}{current_title}'
c.tabs.last_close = 'default-page'
# Statusbar always: it is the browser's vim statusline (mode, url, scroll %, :command line)
c.statusbar.show = 'always'
c.statusbar.padding = {'top': 2, 'bottom': 2, 'left': 4, 'right': 4}
c.scrolling.bar = 'never'
c.scrolling.smooth = False
c.completion.height = '40%'
c.completion.shrink = True
c.completion.scrollbar.width = 0
c.downloads.position = 'bottom'
c.downloads.remove_finished = 5000
c.messages.timeout = 3000
c.hints.chars = 'asdfghjkl'
c.hints.border = f'1px solid {bg}'
c.hints.radius = 2

# Dark everywhere: ask sites for their dark theme, darken the rest (photos untouched).
# Chromium's dark mode is global and needs a restart; there's no per-site switch.
c.colors.webpage.preferred_color_scheme = 'dark'
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'
c.colors.webpage.bg = bg  # about:blank and pages still loading

c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = bg
c.colors.completion.category.fg = blue
c.colors.completion.category.bg = bg
c.colors.completion.category.border.top = bg
c.colors.completion.category.border.bottom = bg
c.colors.completion.item.selected.fg = fg
c.colors.completion.item.selected.bg = sel
c.colors.completion.item.selected.border.top = sel
c.colors.completion.item.selected.border.bottom = sel
c.colors.completion.item.selected.match.fg = yellow
c.colors.completion.match.fg = yellow
c.colors.completion.scrollbar.fg = dim
c.colors.completion.scrollbar.bg = bg

c.colors.statusbar.normal.fg = fg
c.colors.statusbar.normal.bg = bg
c.colors.statusbar.insert.fg = green
c.colors.statusbar.insert.bg = bg
c.colors.statusbar.passthrough.fg = blue
c.colors.statusbar.passthrough.bg = bg
c.colors.statusbar.caret.fg = magenta
c.colors.statusbar.caret.bg = bg
c.colors.statusbar.caret.selection.fg = magenta
c.colors.statusbar.caret.selection.bg = bg
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.bg = bg
c.colors.statusbar.private.fg = fg
c.colors.statusbar.private.bg = line
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.command.private.bg = line
c.colors.statusbar.progress.bg = dim
c.colors.statusbar.url.fg = fg
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.success.http.fg = yellow
c.colors.statusbar.url.warn.fg = orange
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.url.hover.fg = cyan

c.colors.tabs.bar.bg = bg
c.colors.tabs.odd.fg = dim
c.colors.tabs.odd.bg = bg
c.colors.tabs.even.fg = dim
c.colors.tabs.even.bg = bg
c.colors.tabs.selected.odd.fg = fg
c.colors.tabs.selected.odd.bg = line
c.colors.tabs.selected.even.fg = fg
c.colors.tabs.selected.even.bg = line
c.colors.tabs.pinned.odd.fg = dim
c.colors.tabs.pinned.odd.bg = bg
c.colors.tabs.pinned.even.fg = dim
c.colors.tabs.pinned.even.bg = bg
c.colors.tabs.pinned.selected.odd.fg = fg
c.colors.tabs.pinned.selected.odd.bg = line
c.colors.tabs.pinned.selected.even.fg = fg
c.colors.tabs.pinned.selected.even.bg = line

c.colors.hints.fg = bg
c.colors.hints.bg = yellow
c.colors.hints.match.fg = dim
c.colors.keyhint.fg = fg
c.colors.keyhint.suffix.fg = yellow
c.colors.keyhint.bg = line
c.colors.prompts.fg = fg
c.colors.prompts.bg = line
c.colors.prompts.border = f'1px solid {sel}'
c.colors.prompts.selected.fg = fg
c.colors.prompts.selected.bg = sel
c.colors.messages.info.fg = fg
c.colors.messages.info.bg = bg
c.colors.messages.info.border = bg
c.colors.messages.warning.fg = bg
c.colors.messages.warning.bg = yellow
c.colors.messages.warning.border = yellow
c.colors.messages.error.fg = bg
c.colors.messages.error.bg = red
c.colors.messages.error.border = red
c.colors.downloads.bar.bg = bg
c.colors.downloads.start.fg = bg
c.colors.downloads.start.bg = blue
c.colors.downloads.stop.fg = bg
c.colors.downloads.stop.bg = green
c.colors.downloads.error.fg = bg
c.colors.downloads.error.bg = red
c.colors.downloads.system.fg = 'none'
c.colors.downloads.system.bg = 'none'
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.menu.bg = line
c.colors.contextmenu.selected.fg = fg
c.colors.contextmenu.selected.bg = sel
c.colors.contextmenu.disabled.fg = dim
c.colors.contextmenu.disabled.bg = line
c.colors.tooltip.fg = fg
c.colors.tooltip.bg = line

# --- behaviour ------------------------------------------------------------------
c.url.start_pages = ['about:blank']  # instant, nothing to scroll
c.url.default_page = 'about:blank'
c.url.open_base_url = True  # ":open gh" goes to github.com
c.url.searchengines = {
    'DEFAULT': 'https://www.google.com/search?q={}',
    'g': 'https://www.google.com/search?q={}',
    'ddg': 'https://duckduckgo.com/?q={}',
    'gh': 'https://github.com/search?q={}&type=repositories',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'cpp': 'https://en.cppreference.com/mwiki/index.php?search={}',
    'mdn': 'https://developer.mozilla.org/en-US/search?q={}',
    'so': 'https://stackoverflow.com/search?q={}',
    'w': 'https://en.wikipedia.org/w/index.php?search={}',
    # Codeforces has no usable text search: Google, restricted to it
    'cf': 'https://www.google.com/search?q=site%3Acodeforces.com+{}',
    'lc': 'https://leetcode.com/problemset/?search={}',
    'pkg': 'https://pkg.go.dev/search?q={}',
    'rs': 'https://docs.rs/releases/search?query={}',
    'dd': 'https://devdocs.io/#q={}',
    'aw': 'https://wiki.archlinux.org/index.php?search={}',
}

c.auto_save.session = True  # tabs come back after quit/crash...
c.session.lazy_restore = True  # ...but only load when visited
# pages that focus a field on load stay in normal mode: typing into a field is opt-in
# (gi, i, or click / f on it), so your keys never get swallowed by a box you did not pick
c.input.insert_mode.auto_load = False
c.downloads.location.directory = '~/Downloads'
c.downloads.location.prompt = False

# Editor (Ctrl-e in insert mode): nvim in a new Ghostty window. The ghostty CLI can't open
# windows on macOS, so go through `open`; -W blocks until that Ghostty instance quits,
# which it does when nvim exits (quit-after-last-window-closed), as qutebrowser requires.
c.editor.command = [
    '/usr/bin/open', '-W', '-na', 'Ghostty.app', '--args',
    '--quit-after-last-window-closed=true', '--title=qutebrowser-edit',
    f'--env=PATH={BREW}:/usr/bin:/bin:/usr/sbin:/sbin',
    '-e', f'{BREW}/nvim', '{file}', '-c', 'call cursor({line}, {column})',
]

# Privacy/quiet: nothing pops up, nothing plays by itself
c.content.autoplay = False
c.content.notifications.enabled = False
c.content.geolocation = False
c.content.register_protocol_handler = False
c.content.prefers_reduced_motion = True
# Third-party cookies off; sites whose login needs them -> Chrome (,o)
c.content.cookies.accept = 'no-3rdparty'

# Blocking: Brave's ABP engine (needs the `adblock` python package, installed with
# qutebrowser) plus hosts lists. Lists download on first start; refresh with :adblock-update.
# The engine only blocks requests (no element hiding), so cookie lists catch banner
# scripts, not every banner.
c.content.blocking.enabled = True
c.content.blocking.method = 'both'
UBO = 'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters'
c.content.blocking.adblock.lists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
    f'{UBO}/filters.txt',
    f'{UBO}/privacy.txt',
    f'{UBO}/unbreak.txt',
    f'{UBO}/quick-fixes.txt',
    f'{UBO}/annoyances-cookies.txt',
    'https://secure.fanboy.co.nz/fanboy-cookiemonster.txt',  # EasyList Cookie
    'https://secure.fanboy.co.nz/fanboy-annoyance.txt',
]
c.content.blocking.hosts.lists = [
    'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
    'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext',
]

# --- YouTube without the slot machine -------------------------------------------
# Search and watch pages work; feeds and Shorts don't. Full page loads of those are
# redirected here, at request level; YouTube's in-page (SPA) navigation never makes such a
# request, so greasemonkey/youtube-focus.user.js handles that, and hides recommendations.
YT_BLOCKED = re.compile(
    r'^/(shorts(/|$)|(@[^/]+|c/[^/]+|channel/[^/]+|user/[^/]+)/shorts|gaming|hashtag/'
    r'|feed/(?!(subscriptions|history|playlists|library|you|channels|downloads)\b))'
)


def _youtube_focus(req):
    url = req.request_url
    if (req.resource_type == interceptor.ResourceType.main_frame
            and url.host() in ('youtube.com', 'www.youtube.com', 'm.youtube.com')
            and YT_BLOCKED.match(url.path())):
        req.redirect(QUrl('https://www.youtube.com/'))


# :config-source re-runs this file; register once
if not getattr(interceptor, '_dotfiles_youtube', False):
    interceptor.register(_youtube_focus)
    interceptor._dotfiles_youtube = True

# --- keys -----------------------------------------------------------------------
# Defaults stay (J/K tabs, f hints, o/O open, yy copy url, ...). Extras live under ','.
# mpv: video without the page around it (yt-dlp does the fetching)
config.bind(',m', f'spawn --detach {MPV} {{url}}')
config.bind(';m', f'hint links spawn --detach {MPV} {{hint-url}}')
# Bitwarden (rbw): fill login for this site
config.bind(',p', 'spawn --userscript rbw-fill')
# competitive programming: fetch samples + open the problem in tmux/nvim
config.bind(',c', 'spawn --userscript cp')
# fallback browser for sites that break here
config.bind(',o', "spawn /usr/bin/open -a 'Google Chrome' {url}")
