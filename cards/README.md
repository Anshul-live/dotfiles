# cards

Spaced repetition for the Devlogs vault (`~/Documents/Devlogs`). Cards are written
inside the topic notes, so the card and its context stay together. `cards` copies
them into an Anki collection. You review in the terminal, and AnkiWeb sync lets a
phone review the same cards.

```
capture ──> Inbox/ ──> topic note ──> cards in the note ──> cards sync ──> cards review (daily)
<leader>kc   triage    <leader>kn     <leader>ka / kz       <leader>kS     <leader>kR / terminal
```

## Card format

A card is an Obsidian callout. It looks fine in nvim (render-markdown) and in the
Obsidian app.

```markdown
> [!card] What does building a segment tree cost?
> O(n): each of the ~2n nodes is computed once from its children.
```

The callout title is the **front** and the body is the **back**. If the front is
longer than one line, leave the title empty and put a `---` line between front and back:

````markdown
> [!card]
> What does this print?
> ```cpp
> int a = 5;
> cout << (a << 1);
> ```
> ---
> `10`: shifting left by one doubles it.
````

**Cloze** cards hide the marked parts, one card per number:

```markdown
> [!cloze] A segment tree query is {{c1::O(log n)}}, an update is {{c2::O(log n)::complexity}}.
> ---
> Optional extra shown on the back.
```

Rules:

- Markdown works on both sides: code blocks (highlighted), `inline code`, **bold**,
  lists, `$math$`. Cloze markers inside code blocks are not supported.
- A callout inside a fenced code block is treated as an example and ignored.
- An empty `> [!card]` (an unfilled template stub) is ignored.
- **Deck** = `Devlogs::<top folder>`, e.g. `DSA/segment-tree.md` → `Devlogs::DSA`.
  Notes in the vault root go to `Devlogs`. Frontmatter `deck: System Design`
  overrides this.
- **Tags** come from the note's frontmatter `tags`. Every card also gets the `devlogs` tag.
- The back ends with the note it came from (`— DSA › segment-tree`).

After the first sync, `cards` writes a marker line right below each card:

```markdown
> [!card] What does building a segment tree cost?
> O(n)
<!-- anki:1791201417799 h:58e7dd6b42 -->
```

render-markdown and Obsidian's reading view hide the marker. **Leave it alone.** It
links the block to its Anki note, so re-running never duplicates a card. `h:` is a
hash of the card's content: if you edit the card, the next sync **updates** the same
Anki note and keeps its review history. If you move the note to another folder, the
card moves to the matching deck. If you copy a card block, delete the copied marker,
otherwise `cards` skips that block and warns.

The vault is the source of truth. An edit made in Anki or on the phone is
overwritten the next time that card changes in the vault. Fix cards in the note:
during review, `e` opens the note at that card.

## Commands

| command | does |
| --- | --- |
| `cards sync` | scan the vault, add new cards, update edited ones, then sync with AnkiWeb |
| `cards sync -n` | dry run: show what would be added or updated, write nothing |
| `cards push [files]` | like sync but without AnkiWeb (`<leader>kp` runs it on the current note) |
| `cards review [DSA]` | review due cards (all of Devlogs, or one sub-deck); syncs before and after |
| `cards stats` | due counts per deck, today's reviews, 30-day retention |
| `cards new [-f DSA] [-t problem] Title` | new note from `cards/templates/<t>.md`, opened in `$EDITOR` |
| `cards orphans [--delete]` | Anki notes whose card block was deleted from the vault |
| `cards login` | log in to AnkiWeb once (the key goes to the macOS keychain) |
| `cards apy …` | [apy](https://github.com/lervag/apy) on the same collection, e.g. `cards apy list-cards deck:Devlogs::DSA` |

Review keys: `space` shows the answer. Then rate it: `1` again, `2` hard,
`3` good (`space`/`enter` also mean good), `4` easy. Each key shows the next
interval. Other keys: `u` undoes the last answer, `e` edits the card's note (it
is pushed again when you exit the editor), `b` buries the card until tomorrow,
`q` quits.

Safety: a note file is only changed by inserting or replacing marker lines. Writes
go to a temp file that is then atomically renamed into place. If the file changed
on disk while syncing (for example, saved in nvim at that moment), `cards` refuses
to write it. Line endings (LF/CRLF) are kept.

## Daily workflow

1. **During the day:** capture anything worth keeping with `<leader>kc` (one line
   to `Inbox/capture.md`), or start a note with `<leader>kn` (it goes to `Inbox/`).
2. **Same day:** turn captures into notes. Explain each idea in your own words and
   link it to related notes. Move the note into its folder (DSA, Concepts, …).
3. **Write 2-5 cards per note** while it's fresh (`<leader>ka`; select text first
   to turn it into a card; `<leader>kz` for cloze). Good cards are small and test
   one fact, and they ask *why* or *when*, not only *what*. For DSA, card the key
   insight and the invariant, not the whole solution.
4. **Every day:** `cards review` for 10-15 minutes, ideally before new work. Don't
   skip days: the scheduler assumes you show up, and the backlog grows fast.
5. **Weekly:** `cards stats`. If retention drops below ~85%, the cards are too
   big. Split them. Run `cards orphans` now and then.

## Setup

- `uv tool install apyanki`. This provides the `anki` python package (Anki's real
  scheduler and sync code, no desktop app) and `apy`. `bin/cards` runs on that
  tool's python.
- The collection is `~/.local/share/cards/collection.anki2`. It is created on the
  first run with **FSRS** on (Anki's modern scheduler, more accurate than SM-2),
  and the setting syncs to phones. Defaults: 20 new cards per day per deck, 90%
  desired retention. To change them, use AnkiWeb/AnkiMobile/AnkiDroid deck options;
  they sync back.
- Env overrides (used for testing): `CARDS_VAULT`, `CARDS_HOME`.

### Phone (optional)

1. Create a free account at <https://ankiweb.net>.
2. `cards login` (email + password, asked once). Only the sync key is stored, in
   the login keychain as `cards-ankiweb`.
3. `cards sync`. The first sync uploads this collection. If AnkiWeb already has a
   collection, `cards` asks which side wins (upload or download).
4. On the phone: AnkiMobile (iOS, paid) or AnkiDroid (Android, free). Log in with
   the same account and sync.
5. Review on either device. `cards review` syncs before and after, so the two don't
   diverge.

Images aren't synced (media sync is off), so keep cards text and code.
