# dotfiles

A keyboard-only macOS setup for dev, learning and reading: AeroSpace tiling, Ghostty + tmux +
Neovim, terminal apps instead of GUI ones, one colour scheme (vague) everywhere.

## Install

```sh
git clone git@github.com:Anshul-live/dotfiles ~/dotfiles && cd ~/dotfiles
./install.sh            # Homebrew + Brewfile + uv tools, sioyek build, macOS defaults, links
./install.sh --links    # only (re)link configs
./install.sh --macos    # only apply macOS defaults (macos/defaults.sh), then log out/in
sudo ./blocker/install.sh   # distraction blocker, once
```

Links never overwrite: anything already at a target is moved to `<target>.pre-dotfiles`.
After a first install: open Karabiner-Elements and allow its driver and Input Monitoring,
then `aerospace reload-config`. Accounts are set up once, see [Accounts](#accounts).

## The keyboard

| Key | Does |
|---|---|
| **Caps Lock** tap / hold | Esc / Ctrl |
| **Right Cmd** (hold) | **Hyper** = Ctrl+Alt+Cmd, used for everything below (Left Cmd and both Ctrls stay normal) |

| **Right Option** + `h j k l` | arrow keys in GUI apps (WhatsApp, Messages, draw.io, dialogs…); not in Ghostty |

Config: `karabiner/karabiner.json`. Same on the MacBook and an external board.

### Vim keys everywhere

Every tool here moves with `h j k l` (plus `gg`/`G`, `/`, `Ctrl-d`/`Ctrl-u` where it makes sense):
Neovim, the shell, tmux copy mode, qutebrowser, aerc, ikhal, newsboat, spotify_player, yazi,
sioyek, mpv, btop, stig, lazygit, `less`/man, and anything using readline (qalc, sqlite3…).

- **zsh** is in vi mode: `Esc` (tap Caps) for normal mode, then `hjkl w b 0 $ dd ciw u p`,
  `k`/`j` history, `/` search history, `v` edit the line in nvim. The cursor is a block in
  normal mode and a beam in insert; the prompt arrow turns `❮`. Insert mode keeps `Ctrl-a/e/w/u`.
- **mpv**: `h`/`l` seek, `j`/`k` volume, `c` subtitles.
- **GUI apps** without vim keys: Right Option + `hjkl` (above). Obsidian has vim mode on.
  Do once by hand: Chrome → install the **Vimium** extension; Raycast → Settings → Advanced →
  Navigation Bindings → **Vim**; Xcode → Editor → **Vim Mode**.

## Windows and workspaces (AeroSpace)

Every workspace is a letter for what lives there. Apps land on theirs when they open, and
**B N C M open what lives there if the workspace is empty**, so you never land on nothing.

| Hyper + | Workspace |
|---|---|
| `T` | terminal: tmux sessions per project |
| `B` | browser: qutebrowser (Chrome as fallback) |
| `R` | reading: sioyek PDFs |
| `N` | notes: nvim on the vault (tmux session `notes`) |
| `C` | comms: tmux `comms` = 1 mail (aerc), 2 cal (ikhal), 3 rss (newsboat); Messages, WhatsApp |
| `M` | music: tmux `music` (spotify_player) |
| `V` / `D` | video (DaVinci) / design (draw.io, Excalidraw) |
| `1 2 3` | spare |

| Hyper + | Does |
|---|---|
| `Shift` + letter | send the window to that workspace (and follow) |
| `Tab` | previous workspace |
| `h j k l` / `Shift+h j k l` | focus / move window |
| `f` | fullscreen |
| `/` / `,` | side-by-side tiles / full-screen stack |
| `-` / `=` | shrink / grow |
| `` ` `` | drop-down terminal (Ghostty quick terminal) |
| `Space` | WINDOW mode, then one key (sketchybar shows a cheat-sheet) |

WINDOW mode: `d s v m e` run a setup (dev / study / video / comms / design, see
`aerospace/setup.sh`), `h j k l` etc. work without Hyper, `t` float/tile, `r` reset layout,
`x` close, `c` reload config, `Esc` back.

## Terminal: Ghostty + tmux + zsh

tmux prefix is **Ctrl-a**.

| Key | Does |
|---|---|
| `prefix f` | pick a project → its session (windows: 1 code/nvim, 2 run, 3 git/lazygit) |
| `prefix Tab` | previous session |
| `prefix c` / `n` / `p` / number | new / next / previous / go to window |
| `prefix \|` / `-` | split right / down |
| `Ctrl h j k l` | move between panes and nvim splits |
| `prefix r` / `prefix ?` | reload config / list keys |

A project can define its own windows with an executable `.tmux-layout` (gets session name and
dir as arguments; see `bin/tmux-sessionizer`).

Shell (vi mode, see above): `y` file manager (cd's to where you quit), `z <part>` jump to dir, `Ctrl-r` history,
`Ctrl-t` files, `ls`/`ll`/`lt` (eza), `cat` (bat), `gs gd gl gc gp` git.

## Neovim

`<Space>` is leader. **Press `<Space>` and wait: which-key lists everything.** The main groups:

| Key | Does |
|---|---|
| `<leader>ff` / `fr` / `fb` | files / recent / buffers |
| `<leader>r` / `R` | run this file or project (`input.txt` next to it is piped to stdin) / with args |
| `<leader>e` | ask Claude Code about the error or code here |
| `<leader>n` | this project's scratch notes |
| `<leader>m` | pick a mode; or enter one: `a` AI, `d` debug, `g` git, `t` test, `od` docker, `oh` http, `ob` db |
| `<leader>k…` | notes (below) |
| `<leader>j…` | competitive programming (below) |
| `<BS>` | previous file |

In a mode, single keys do that mode's actions; `Esc` or `q` leaves.

## Browser: qutebrowser

Vim keys: `o` open, `O` new tab, `f` follow link, `F` link in new tab, `H`/`L` back/forward,
`J`/`K` tabs, `d` close tab, `/` search page, `:` command line.

| Key | Does |
|---|---|
| `,m` / `;m` | play this page / a hinted link in mpv |
| `,p` | fill login from Bitwarden (rbw); several matches: type the number shown |
| `,c` | send this problem to nvim (cp-fetch) |
| `,o` | open this page in Chrome (sites that break, Google logins) |
| `Ctrl-e` in a text field | edit it in nvim |

Search from `o`: `g` Google (default), `ddg`, `gh` GitHub, `yt` YouTube, `cpp` cppreference,
`mdn`, `so`, `w` Wikipedia, `cf` Codeforces, `lc` LeetCode, `pkg` Go, `rs` docs.rs,
`dd` devdocs, `aw` Arch wiki, e.g. `o cpp vector`.

YouTube works for search and videos only: no home feed, Shorts or recommendations.
From scripts use `qb <url>` (handles starting qutebrowser; `qb -w` = new window).

## Competitive programming (C++)

Every problem lives in one repo, `~/Desktop/code/dsa`
([github.com/Anshul-live/dsa](https://github.com/Anshul-live/dsa), public), with its plan next to
the code:

```
leetcode/0001.two-sum/                 solution.cpp  testcases.txt  question.md   (leetgo)
codeforces/1900/1900A-…/               main.cpp      tests/N.in|out problem.md    (cp-fetch)
  + plan.md               frontmatter (status, difficulty, tags) + plan, from your DSA template
  + sketch.excalidraw.md  drawing; the repo is DSA/Solutions in the Obsidian vault
README.md                 table of everything, rebuilt by cp-index
```

**Get a problem:** `,c` on any problem page in qutebrowser (Codeforces, CSES, AtCoder, LeetCode),
`cp-fetch <url>`, or from nvim (below). It opens nvim as statement | plan | code, in CP mode.

**Plan first:** the cursor starts in `plan.md` (approach, complexity, edge cases) when it's
empty, and test/submit warn until it's filled. `d` opens the sketch in Obsidian (Excalidraw);
it auto-exports `sketch.excalidraw.svg`, which `plan.md` shows on GitHub.

**CP mode** (`<leader>j`, on by itself when a problem opens; `Esc`/`q` leaves it):

| Key | Does |
|---|---|
| `p` / `f` / `b` | pick any LeetCode problem / fetch a URL / browse your solutions (plan preview) |
| `1` `2` `3` | statement / plan / code |
| `t` | run tests locally (LeetCode: `testcases.txt` via leetgo; others: sanitizers, AC/WA/TLE/RE) |
| `T` | LeetCode: run on LeetCode's servers |
| `s` | LeetCode: submit; Accepted marks it solved, commits and pushes. Others: copy + open the page |
| `S` | mark solved + commit + push (after a Codeforces/CSES/AtCoder accept) |
| `n` / `r` | new test case / last results |
| `d` / `w` | draw the sketch / open the problem in qutebrowser |

LeetCode from the shell: `lc pick 1`, `lc test 1 -L`, `lc submit 1` (`lc` is leetgo run from the
repo with your cookies). Testing on LeetCode and submitting need two rbw entries, `LeetCode
session` and `LeetCode csrftoken`: log in at leetcode.com in qutebrowser, `wi` → Application →
Cookies, copy `LEETCODE_SESSION` and `csrftoken` (redo when LeetCode logs you out).

Codeforces blocks scripts: fetch it with `,c` from qutebrowser (uses the page you see).
`<bits/stdc++.h>` works (a stand-in lives in `~/Desktop/code/dsa/include`).

## Notes and flashcards

Notes are markdown in the Obsidian vault `~/Documents/Devlogs`, written in nvim (Hyper+N).
The Obsidian app is only for the graph view (`<leader>ko`).

| Key | Does |
|---|---|
| `<leader>kn` / `kN` | new note (into `Inbox/`) / from a template |
| `<leader>kc` | quick capture: one line into `Inbox/capture.md` |
| `<leader>kd` / `ky` / `kD` | today / yesterday / pick a daily note |
| `<leader>kf` / `ks` | find note / search in notes |
| `<leader>kb` / `kl` / `kt` | backlinks / links / tags |
| `<leader>kx` / `kr` / `ke` | toggle checkbox / rename (fixes links) / extract selection to a note |
| `<leader>ka` / `kz` | add a flashcard / a cloze (`{{c1::…}}`) |
| `<leader>kR` / `kS` / `ki` | review cards / sync cards / stats |

`Enter` on a `[[link]]` follows it.

Flashcards live inside notes as callouts:

```markdown
> [!card] What does a segment tree query cost?
> O(log n)

> [!cloze]
> Dijkstra fails with {{c1::negative edge weights}}.
```

`cards sync` turns them into Anki cards (deck = top folder, FSRS scheduling) and syncs AnkiWeb,
so they also show up in AnkiMobile/AnkiDroid. Daily: `cards review` (10–15 min).
More in `cards/README.md`.

## Terminal apps

Every app also has a plain-word alias (`mail`, `cal`, `news`, `music`, `pdf`, `calc`, `solve <url>`,
`pick`…). Type `tools` for the full list (`zsh/aliases.zsh`).

| App | Start | Keys worth knowing |
|---|---|---|
| **aerc** mail | Hyper+C, window 1 | `j/k`, `Enter` read, `m` compose, `Rr` reply / `rr` reply all, `a` archive, `d` trash, `*` star, `gi gs gd ga gt` Inbox/Sent/Drafts/All/Starred, `gf` pick folder, `gl` open link, `?` help |
| **matcha** mail | `matcha` | `j/k`, `Enter` open, `r`/`R` reply/reply all, `f` forward, `a` archive, `d` delete, `v` select, `T` threads, `/` search, `h/l` tabs, `:` commands. Same Gmail account as aerc |
| **ikhal** calendar | Hyper+C, window 2 | `n` new event, `Enter` view, `?` help. Also `khal list today 7d` |
| **newsboat** RSS | Hyper+C, window 3 | `j/k`, `l` open, `h` back, `o` open in browser, `v` play in mpv, `y` copy link, `n` next unread, `R` reload. Feeds: `newsboat/urls` |
| **spotify_player** | Hyper+M | `j/k` `gg/G` `Ctrl-d/u` move, `h` back, `Enter` open, `Space` play/pause, `n`/`p` next/prev, `g s` search Spotify, `/` filter, `D` device, `?` help. It is the remote; the Spotify app (started hidden) plays the sound, since Spotify blocks the built-in player for newer accounts |
| **yazi** files | `y` | `hjkl`, `Enter` open (nvim/sioyek/mpv/qutebrowser by type), `Space` select, `y`/`x`/`p` copy/cut/paste, `d` trash, `a` new, `r` rename, `.` hidden, `q` quit |
| **sioyek** PDFs | `open file.pdf` / from yazi | `j/k`, `Ctrl-d/u` screen, `J/K` page, `w` fit width, `i` colours, `/` search, `t` contents, `m`/`` ` `` marks |
| **mpv** video | `mpv <file or url>` | `Space` pause, `h/l` ±5s, `H/L` ±60s, `j/k` volume, `c` subtitles, `[ ]` speed, `f` fullscreen, `a` A-B loop, `q` quit (resumes where you stopped) |
| **btop** | `btop` | processes; vim keys |
| **stig** torrents | `stig` | transmission daemon runs in the background (brew service), downloads to `~/Downloads/torrents` |
| **qalc** | `qalc 5 GiB to MB` | calculator with units and currencies |
| **ouch** | `ouch d file.zip` / `ouch c dir out.tar.gz` | any archive format |
| **lazygit / lazydocker** | tmux window 3 / `<leader>od` | |
| **docker** | `docker …` | runs on colima (starts at login) |

Raycast stays for clipboard history, snippets, calculator and launching apps.

## Distraction blocker

Social feeds and streaming sites are blocked system-wide (all browsers and apps) via
`/etc/hosts`, enforced by a root daemon that restores it within seconds.

```sh
block list                 # what's blocked
block add example.com      # instant
block remove example.com   # type a long sentence, then it unblocks after 24 hours
block pending / cancel <d> # queued unblocks / cancel one
block status
```

Seed list: `blocker/blocklist.txt` (YouTube is not blocked; qutebrowser strips its feed).

## Accounts

Secrets never live in the repo: configs read them from Bitwarden through `rbw`.

| What | Bitwarden item | Setup |
|---|---|---|
| Bitwarden | — | `rbw config set email …`, `rbw register`, `rbw login` |
| Gmail (aerc) | `Gmail app password` | app password at myaccount.google.com/apppasswords, IMAP on |
| Google Calendar | `vdirsyncer google client` (user = client id, password = secret) | Cloud project with CalDAV API + Desktop OAuth client, then `vdirsyncer discover google && vdirsyncer sync` |
| Spotify | `spotify client id` | app at developer.spotify.com, redirect `http://127.0.0.1:8989/login`, then `spotify_player authenticate`; also log in to the Spotify app once (it plays the audio) |
| AnkiWeb | — | `cards login` |

Calendar syncs every 15 min (`~/Library/LaunchAgents/com.anshul.vdirsyncer.plist`).

## Layout of this repo

| Dir | What |
|---|---|
| `aerospace/`, `sketchybar/`, `borders/`, `karabiner/` | windows, bar, focus outline, keyboard |
| `ghostty/`, `tmux/`, `zsh/`, `starship/`, `nvim/` | terminal, multiplexer, shell, prompt, editor |
| `qutebrowser/`, `mpv/`, `sioyek/` | browser, video, PDFs |
| `aerc/`, `matcha/`, `khal/`, `vdirsyncer/`, `newsboat/`, `spotify_player/`, `yazi/`, `btop/`, `stig/` | terminal apps |
| `blocker/` | distraction blocker |
| `cards/` | flashcards from notes |
| `bin/` | `tmux-sessionizer`, `ws-session`, `cp-fetch`, `cp-index`, `lc`, `qb`, `cards`, `block` |
| `macos/defaults.sh` | system settings (key repeat, no animations, Dock, Finder…) |
