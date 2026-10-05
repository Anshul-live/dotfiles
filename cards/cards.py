"""cards: spaced repetition for the Devlogs vault, in the terminal.

Cards live inside the topic notes as callouts (format: cards/README.md). This
script finds them, adds/updates them in an Anki collection, reviews them with
Anki's own scheduler (FSRS), and syncs with AnkiWeb so a phone can review too.

Runs on the python of the `apyanki` uv tool (bin/cards picks it), because that
env already has the `anki` package (the real Anki scheduler + sync, no desktop
app needed) and apy's markdown->HTML field conversion, which keeps the original
markdown inside the field so `apy edit` and our review can show it again.
"""

from __future__ import annotations

import argparse
import getpass
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

HOME = Path.home()
VAULT = Path(os.environ.get("CARDS_VAULT", HOME / "Documents/Devlogs")).expanduser().resolve()
STATE = Path(os.environ.get("CARDS_HOME", HOME / ".local/share/cards")).expanduser()
COLLECTION = STATE / "collection.anki2"
ROOT_DECK = "Devlogs"
MANAGED_TAG = "devlogs"  # every note added from the vault; lets `orphans` find stale ones
KEYCHAIN = ("cards-ankiweb", "ankiweb")  # service, account
SKIP_DIRS = {"Templates", ".obsidian", ".trash", ".git"}

# ---------------------------------------------------------------- parsing

CALLOUT = re.compile(r"^>\s*\[!(card|cloze)\][+-]?\s?(.*)$", re.IGNORECASE)
MARKER = re.compile(r"^<!--\s*anki:(\d+)(?:\s+h:([0-9a-f]+))?\s*-->\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")


@dataclass
class Card:
    path: Path
    start: int  # index of the callout's first line
    end: int  # index of the line after the callout
    kind: str  # "card" | "cloze"
    front: str
    back: str
    deck: str
    tags: list[str]
    nid: int | None = None
    hash_: str | None = None
    marker_line: int | None = None  # index of the existing marker line
    problem: str | None = None

    @property
    def where(self) -> str:
        return f"{self.path.relative_to(VAULT)}:{self.start + 1}"

    @property
    def source(self) -> str:
        return str(self.path.relative_to(VAULT).with_suffix("")).replace("/", " › ")

    def digest(self) -> str:
        blob = "\x1f".join([self.kind, self.deck, self.front, self.back, " ".join(self.tags)])
        return hashlib.sha1(blob.encode()).hexdigest()[:10]


@dataclass
class NoteFile:
    path: Path
    lines: list[str]  # with line endings, exactly as read
    mtime: float
    cards: list[Card] = field(default_factory=list)


def frontmatter(lines: list[str]) -> dict[str, object]:
    """The few frontmatter keys we use (deck, tags); a tiny YAML subset on purpose."""
    meta: dict[str, object] = {}
    if not lines or lines[0].strip() != "---":
        return meta
    key = None
    for line in lines[1:]:
        s = line.rstrip("\r\n")
        if s.strip() in ("---", "..."):
            break
        if m := re.match(r"^(\w[\w-]*):\s*(.*)$", s):
            key, val = m.group(1).lower(), m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                meta[key] = [v.strip().strip("'\"") for v in val[1:-1].split(",") if v.strip()]
            elif val:
                meta[key] = val.strip("'\"") if key != "tags" else val.split()
            else:
                meta[key] = []
        elif key and (m := re.match(r"^\s*-\s+(.*)$", s)) and isinstance(meta.get(key), list):
            meta[key].append(m.group(1).strip().strip("'\""))  # type: ignore[union-attr]
    return meta


def clean_tag(t: str) -> str:
    return re.sub(r"\s+", "_", t.strip().lstrip("#"))


def deck_for(path: Path, meta: dict[str, object]) -> str:
    if isinstance(meta.get("deck"), str) and meta["deck"]:
        return f"{ROOT_DECK}::{meta['deck']}"
    parts = path.relative_to(VAULT).parts
    return f"{ROOT_DECK}::{parts[0]}" if len(parts) > 1 else ROOT_DECK


def split_card(kind: str, title: str, body: list[str]) -> tuple[str, str]:
    """front/back of a callout: title is the front unless a `---` line splits the body."""
    in_code, sep = False, None
    for i, line in enumerate(body):
        if FENCE.match(line):
            in_code = not in_code
        elif not in_code and line.strip() == "---":
            sep = i
            break
    if sep is None:
        return title.strip(), "\n".join(body).strip()
    front = "\n".join(([title] if title.strip() else []) + body[:sep]).strip()
    return front, "\n".join(body[sep + 1 :]).strip()


def parse(path: Path) -> NoteFile:
    with path.open(encoding="utf-8", newline="") as f:
        text = f.read()
    nf = NoteFile(path, text.splitlines(keepends=True), path.stat().st_mtime)
    meta = frontmatter(nf.lines)
    tags = [clean_tag(t) for t in (meta.get("tags") or []) if isinstance(t, str) and clean_tag(t)]
    deck = deck_for(path, meta)
    lines = [l.rstrip("\r\n") for l in nf.lines]
    i, in_code = 0, False
    while i < len(lines):
        line = lines[i]
        if FENCE.match(line):  # a callout shown inside a code block is an example, not a card
            in_code = not in_code
            i += 1
            continue
        m = None if in_code else CALLOUT.match(line)
        if not m:
            i += 1
            continue
        start, j = i, i + 1
        while j < len(lines) and lines[j].startswith(">"):
            j += 1
        body = [re.sub(r"^>\s?", "", l) for l in lines[start + 1 : j]]
        kind = m.group(1).lower()
        front, back = split_card(kind, m.group(2), body)
        if not front and not back:  # an unfilled template stub, not a card yet
            i = j
            continue
        card = Card(path, start, j, kind, front, back, deck, list(tags))
        if j < len(lines) and (mm := MARKER.match(lines[j])):
            card.nid, card.hash_, card.marker_line = int(mm.group(1)), mm.group(2), j
        if kind == "card" and not (front and back):
            card.problem = "needs a front (title) and a back (body)"
        if kind == "cloze" and not re.search(r"\{\{c\d+::", front):
            card.problem = "cloze without {{c1::...}}"
        nf.cards.append(card)
        i = j
    return nf


def vault_files(only: list[str] | None = None) -> list[Path]:
    if only:
        return [Path(p).expanduser().resolve() for p in only]
    out = []
    for root, dirs, files in os.walk(VAULT):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS and not d.startswith("."))
        out += [Path(root) / f for f in sorted(files) if f.endswith(".md")]
    return out


def write_markers(nf: NoteFile, markers: dict[int, str]) -> None:
    """Insert/replace marker lines (keyed by card start line) and nothing else.

    Atomic (temp file + rename in the same dir) and refuses if the file changed
    since it was read, so a note being edited in nvim is never clobbered."""
    if not markers:
        return
    if nf.path.stat().st_mtime != nf.mtime:
        raise RuntimeError(f"{nf.path} changed while syncing; re-run")
    eol = "\r\n" if nf.lines and nf.lines[0].endswith("\r\n") else "\n"
    out = list(nf.lines)
    # bottom-up so earlier indices stay valid
    for card in sorted(nf.cards, key=lambda c: c.start, reverse=True):
        if card.start not in markers:
            continue
        new = markers[card.start] + eol
        if card.marker_line is not None:
            out[card.marker_line] = new if out[card.marker_line].endswith(("\n", "\r")) else new.rstrip("\r\n")
        else:
            if card.end - 1 < len(out) and not out[card.end - 1].endswith(("\n", "\r")):
                out[card.end - 1] += eol  # callout was the last line, without a newline
            out.insert(card.end, new)
    fd, tmp = tempfile.mkstemp(dir=nf.path.parent, prefix=f".{nf.path.name}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write("".join(out))
        os.chmod(tmp, nf.path.stat().st_mode & 0o777)
        os.replace(tmp, nf.path)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


# ---------------------------------------------------------------- collection


def open_col():
    from anki.collection import Collection

    STATE.mkdir(parents=True, exist_ok=True)
    fresh = not COLLECTION.exists()
    cwd = os.getcwd()
    col = Collection(str(COLLECTION))
    os.chdir(cwd)  # anki chdirs into the media folder
    if fresh:
        col.set_config("fsrs", True)  # FSRS scheduler instead of SM-2 (synced to phones too)
    return col


def to_field(md: str) -> str:
    from apyanki.config import cfg
    from apyanki.fields import convert_text_to_field

    cfg["markdown_pygments_style"] = "github-dark"  # code blocks readable on dark phones
    return convert_text_to_field(md, use_markdown=True)


def from_field(html: str) -> str:
    from apyanki.fields import convert_field_to_text

    return convert_field_to_text(html, check_consistency=False)


def fill(col, note, card: Card) -> None:
    note.fields[0] = to_field(card.front)
    note.fields[1] = to_field(card.back + f"\n\n*— {card.source}*")
    note.tags = sorted(set(card.tags) | {MANAGED_TAG})


def push(args, col=None) -> int:
    """Scan the vault and add/update cards. Returns the number of problems.
    `col`: an already open collection (left open); otherwise one is opened and closed."""
    from anki.errors import NotFoundError

    own = col is None
    if own:
        col = None if args.dry_run and not COLLECTION.exists() else open_col()
    added = updated = same = problems = 0
    seen: dict[int, str] = {}
    try:
        for path in vault_files(getattr(args, "files", None)):
            nf = parse(path)
            markers: dict[int, str] = {}
            for card in nf.cards:
                if card.problem:
                    problems += 1
                    print(f"  skip  {card.where}: {card.problem}")
                    continue
                if card.nid is not None and card.nid in seen:
                    problems += 1
                    print(f"  skip  {card.where}: anki:{card.nid} already used at {seen[card.nid]} (copied block? delete this marker)")
                    continue
                digest = card.digest()
                note = None
                if card.nid is not None:
                    seen[card.nid] = card.where
                    try:
                        note = col.get_note(card.nid) if col else None
                    except NotFoundError:
                        if not args.readd:
                            problems += 1
                            print(f"  gone  {card.where}: anki:{card.nid} not in the collection (deleted?); --readd to add it again")
                            continue
                    if note is not None and card.hash_ == digest:
                        same += 1
                        continue
                if note is None:  # new (or re-added)
                    added += 1
                    print(f"  add   {card.where}  [{card.deck}]  {card.front.splitlines()[0][:60]}")
                    if args.dry_run:
                        continue
                    model = col.models.by_name("Cloze" if card.kind == "cloze" else "Basic")
                    note = col.new_note(model)
                    fill(col, note, card)
                    col.add_note(note, col.decks.id(card.deck))
                else:
                    updated += 1
                    print(f"  edit  {card.where}  {card.front.splitlines()[0][:60]}")
                    if args.dry_run:
                        continue
                    fill(col, note, card)
                    col.update_note(note)
                    did = col.decks.id(card.deck)
                    moved = [c for c in note.card_ids() if col.get_card(c).did != did]
                    if moved:
                        col.set_deck(moved, did)  # note moved to another folder
                markers[card.start] = f"<!-- anki:{note.id} h:{digest} -->"
                seen[note.id] = card.where
            if not args.dry_run:
                write_markers(nf, markers)
    finally:
        if col and own:
            col.close()
    verb = "would add" if args.dry_run else "added"
    print(f"cards: {verb} {added}, {'would update' if args.dry_run else 'updated'} {updated}, unchanged {same}, problems {problems}")
    return problems


# ---------------------------------------------------------------- AnkiWeb


def _keychain(*a: str) -> subprocess.CompletedProcess:
    return subprocess.run(["security", *a, "-s", KEYCHAIN[0], "-a", KEYCHAIN[1]], capture_output=True, text=True)


def load_auth():
    from anki.sync import SyncAuth

    r = _keychain("find-generic-password", "-w")
    if r.returncode != 0 or not r.stdout.strip():
        return None
    endpoint = None
    if (STATE / "sync.json").exists():
        endpoint = json.loads((STATE / "sync.json").read_text()).get("endpoint")
    return SyncAuth(hkey=r.stdout.strip(), endpoint=endpoint or None)


def save_endpoint(endpoint: str | None) -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    (STATE / "sync.json").write_text(json.dumps({"endpoint": endpoint or None}))


def login(args) -> int:
    user = input("AnkiWeb email: ").strip()
    pw = getpass.getpass("AnkiWeb password: ")
    col = open_col()
    try:
        auth = col.sync_login(user, pw, None)
    finally:
        col.close()
    # the hkey (not the password) goes to the login keychain
    subprocess.run(["security", "add-generic-password", "-U", "-s", KEYCHAIN[0], "-a", KEYCHAIN[1], "-w", auth.hkey], check=True)
    save_endpoint(auth.endpoint)
    print("logged in; run `cards sync`")
    return 0


def ankiweb(col, *, quiet: bool = False) -> bool:
    """Sync the collection with AnkiWeb. Media (images) are not synced."""
    from anki.sync_pb2 import SyncCollectionResponse as R

    auth = load_auth()
    if auth is None:
        if not quiet:
            print("ankiweb: not logged in (run `cards login` once); skipped")
        return False
    out = col.sync_collection(auth, sync_media=False)
    if out.new_endpoint:
        auth.endpoint = out.new_endpoint
        save_endpoint(out.new_endpoint)
    if out.server_message:
        print(f"ankiweb: {out.server_message}")
    req = out.required
    if req in (R.NO_CHANGES, R.NORMAL_SYNC):
        if not quiet:
            print("ankiweb: synced")
        return True
    if req == R.FULL_DOWNLOAD:
        upload = False  # nothing local yet: take AnkiWeb's copy
    elif req == R.FULL_UPLOAD:
        upload = True  # AnkiWeb is empty: send ours
    else:  # both sides changed in incompatible ways (e.g. first sync of two collections)
        if not sys.stdin.isatty():
            print("ankiweb: full sync needed; run `cards sync` in a terminal to choose")
            return False
        print("ankiweb: the collection here and on AnkiWeb can't be merged. One side must win:")
        print("  u  upload   (AnkiWeb + phone get THIS collection)")
        print("  d  download (this collection is replaced by AnkiWeb's)")
        choice = input("  [u/d/anything else = cancel] ").strip().lower()
        if choice not in ("u", "d"):
            print("ankiweb: cancelled")
            return False
        upload = choice == "u"
    print(f"ankiweb: full {'upload' if upload else 'download'}…")
    col.close_for_full_sync()
    try:
        col.full_upload_or_download(auth=auth, server_usn=None, upload=upload)
    finally:
        col.reopen(after_full_sync=True)
    print("ankiweb: synced")
    return True


def sync(args) -> int:
    problems = push(args)
    if args.dry_run or args.offline:
        return 1 if problems else 0
    col = open_col()
    try:
        ankiweb(col)
    finally:
        col.close()
    return 1 if problems else 0


# ---------------------------------------------------------------- review


CLOZE = re.compile(r"\{\{c(\d+)::(.*?)(?:::(.*?))?\}\}", re.DOTALL)


def faces(col, card) -> tuple[str, str]:
    """Question/answer as markdown (from the original markdown kept in the fields)."""
    note = card.note()
    if note.note_type()["type"] == 1:  # cloze
        text, extra, ord_ = from_field(note.fields[0]), from_field(note.fields[1]), card.ord + 1

        def q(m):
            return (f"**[{m.group(3) or '…'}]**") if int(m.group(1)) == ord_ else m.group(2)

        def a(m):
            return f"**`{m.group(2)}`**" if int(m.group(1)) == ord_ else m.group(2)

        return CLOZE.sub(q, text), CLOZE.sub(a, text) + ("\n\n---\n\n" + extra if extra.strip() else "")
    return from_field(note.fields[0]), from_field(note.fields[1])


def editor() -> list[str]:
    return shlex.split(os.environ.get("VISUAL") or os.environ.get("EDITOR") or "nvim")


def find_source(nid: int) -> tuple[Path, int] | None:
    pat = f"anki:{nid}"
    for path in vault_files():
        with path.open(encoding="utf-8") as f:
            for i, line in enumerate(f):
                if pat in line:
                    return path, i
    return None


def review(args) -> int:
    import anki.collection  # noqa: F401  (must load before anki.cards: circular import)
    import readchar
    from anki.cards import Card as AnkiCard
    from anki.scheduler_pb2 import CardAnswer
    from rich.console import Console
    from rich.markdown import Markdown
    from rich.panel import Panel
    from rich.rule import Rule

    con = Console()
    col = open_col()
    try:
        if not args.offline:
            with con.status("syncing…"):
                ankiweb(col, quiet=True)
        deck = f"{ROOT_DECK}::{args.deck}" if args.deck and not args.deck.startswith(ROOT_DECK) else (args.deck or ROOT_DECK)
        did = col.decks.id_for_name(deck)
        if did is None:
            con.print(f"[red]no deck {deck}[/] (run `cards sync` first?)")
            return 1
        col.decks.select(did)
        ratings = [("1", CardAnswer.AGAIN, "again", "#d8647e"), ("2", CardAnswer.HARD, "hard", "#e0a363"),
                   ("3", CardAnswer.GOOD, "good", "#7fa563"), ("4", CardAnswer.EASY, "easy", "#6e94b2")]
        done = 0
        while True:
            queued = col.sched.get_queued_cards(fetch_limit=1)
            if not queued.cards:
                con.print(Rule(style="#606079"))
                con.print(f"[#7fa563]done[/] — {done} reviewed. Nothing else due in {deck}.")
                break
            qc = queued.cards[0]
            card = AnkiCard(col)
            card._load_from_backend_card(qc.card)
            card.start_timer()
            q, a = faces(col, card)
            counts = f"[#6e94b2]{queued.new_count} new[/]  [#d8647e]{queued.learning_count} learn[/]  [#7fa563]{queued.review_count} due[/]"
            con.clear()
            con.print(f"{counts}   [#606079]{col.decks.name(card.did)}[/]")
            con.print(Panel(Markdown(q), border_style="#333738", padding=(1, 2)))
            con.print("[#606079]space show · u undo last · e edit note · b bury · q quit[/]")
            key = readchar.readkey()
            if key in ("q", readchar.key.ESC, readchar.key.CTRL_C):
                break
            if key == "b":
                col.sched.bury_cards([card.id])
                continue
            if key == "e":
                edit_source(con, col, card.nid)
                continue
            if key == "u":  # undo the previous answer; that card comes back
                if done and col.undo_status().undo:
                    col.undo()
                    done -= 1
                continue
            con.print(Panel(Markdown(a), border_style="#606079", padding=(1, 2)))
            # strip the unicode isolate marks Anki wraps numbers in
            labels = [l.replace("\u2068", "").replace("\u2069", "") for l in col.sched.describe_next_states(qc.states)]
            con.print("   ".join(f"[{c}]{k} {n}[/] [#606079]{l}[/]" for (k, _, n, c), l in zip(ratings, labels))
                      + "   [#606079]u undo · e edit · q quit[/]")
            while True:
                key = readchar.readkey()
                if key in ("1", "2", "3", "4", " ", readchar.key.ENTER, "u", "e", "q", readchar.key.CTRL_C):
                    break
            if key in ("q", readchar.key.CTRL_C):
                break
            if key == "e":
                edit_source(con, col, card.nid)
                continue
            if key == "u":
                if done and col.undo_status().undo:
                    col.undo()
                    done -= 1
                continue
            rating = ratings[int(key) - 1][1] if key.isdigit() else CardAnswer.GOOD  # space/enter = good
            col.sched.answer_card(col.sched.build_answer(card=card, states=qc.states, rating=rating))
            done += 1
        if not args.offline and done:
            with con.status("syncing…"):
                ankiweb(col, quiet=True)
    finally:
        col.close()
    return 0


def edit_source(con, col, nid: int) -> None:
    """Open the note the card came from at the card; push it again afterwards."""
    found = find_source(nid)
    if not found:
        con.print(f"[#e0a363]anki:{nid} isn't in the vault[/]")
        return
    path, line = found
    subprocess.run([*editor(), f"+{max(line, 1)}", str(path)])  # line above the marker
    push(argparse.Namespace(dry_run=False, readd=False, files=[str(path)]), col)


# ---------------------------------------------------------------- misc


def stats(args) -> int:
    col = open_col()
    try:
        tree = col.sched.deck_due_tree()
        rows = []

        def walk(node, depth):
            if node.name and (node.name == ROOT_DECK or depth > 1 or args.all):
                rows.append(("  " * max(depth - 1, 0) + node.name, node.new_count, node.learn_count, node.review_count))
            for child in node.children:
                if depth == 0 and child.name != ROOT_DECK and not args.all:
                    continue
                walk(child, depth + 1)

        walk(tree, 0)
        print(f"{'deck':28} {'new':>5} {'learn':>6} {'due':>5}")
        for name, n, l, r in rows:
            print(f"{name:28} {n:>5} {l:>6} {r:>5}")
        cutoff = (col.sched.day_cutoff - 86400) * 1000
        today, again = col.db.first("select count(), sum(ease = 1) from revlog where id > ?", cutoff)
        month = (col.sched.day_cutoff - 30 * 86400) * 1000
        n, passed = col.db.first("select count(), sum(ease > 1) from revlog where id > ? and type = 1", month)
        print()
        print(f"today: {today or 0} reviews, {again or 0} again")
        print(f"30-day retention (mature+young reviews): {f'{100 * passed / n:.0f}% of {n}' if n else 'n/a'}")
        print(f"notes: {col.note_count()}   cards: {col.card_count()}   fsrs: {'on' if col.get_config('fsrs', False) else 'off'}")
    finally:
        col.close()
    return 0


def orphans(args) -> int:
    """Anki notes added from the vault whose card block no longer exists."""
    live = {c.nid for p in vault_files() for c in parse(p).cards if c.nid}
    col = open_col()
    try:
        stale = [nid for nid in col.find_notes(f"tag:{MANAGED_TAG}") if nid not in live]
        for nid in stale:
            print(f"  {nid}  {from_field(col.get_note(nid).fields[0]).splitlines()[0][:70]}")
        if stale and args.delete:
            col.remove_notes(stale)
            print(f"deleted {len(stale)}")
        elif stale:
            print(f"{len(stale)} orphaned; `cards orphans --delete` removes them (and their review history)")
        else:
            print("no orphans")
    finally:
        col.close()
    return 0


TEMPLATES = Path(__file__).resolve().parent / "templates"  # shared with obsidian.nvim


def new(args) -> int:
    title = " ".join(args.title) or input("title: ").strip()
    if not title:
        return 1
    slug = re.sub(r"[^\w\s-]", "", title).strip().lower()
    slug = re.sub(r"[\s_]+", "-", slug)
    path = VAULT / (args.folder or "Inbox") / f"{slug}.md"
    if not path.exists():
        from datetime import date

        tpl = (TEMPLATES / f"{args.template}.md").read_text(encoding="utf-8")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(tpl.replace("{{title}}", title).replace("{{date}}", date.today().isoformat()), encoding="utf-8")
    cmd = [*editor(), str(path)]
    os.execvp(cmd[0], cmd)


def apy(args) -> int:
    """apy against this collection, e.g. `cards apy edit nid:123`, `cards apy list-cards deck:Devlogs`."""
    # apy wants an Anki desktop profile folder (prefs21.db); there is none, so point it
    # straight at the collection file before its CLI reads the config
    from apyanki.config import cfg

    cfg["base_path"] = None
    cfg["collection_db_path"] = str(COLLECTION)
    cfg["markdown_pygments_style"] = "github-dark"
    from apyanki.cli import main as apy_main

    return apy_main(args=args.rest, prog_name="cards apy", standalone_mode=True)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="cards", description="Spaced repetition for the Devlogs vault (see cards/README.md)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    def pushy(p):
        p.add_argument("-n", "--dry-run", action="store_true", help="show what would change, write nothing")
        p.add_argument("--readd", action="store_true", help="re-add cards whose Anki note was deleted")
        p.add_argument("files", nargs="*", help="only these notes (default: whole vault)")

    p = sub.add_parser("sync", help="add/update cards from the vault, then sync AnkiWeb")
    pushy(p)
    p.add_argument("--offline", action="store_true", help="skip AnkiWeb")
    p.set_defaults(fn=sync)
    p = sub.add_parser("push", help="add/update cards from the vault only")
    pushy(p)
    p.set_defaults(fn=lambda a: 1 if push(a) else 0)
    p = sub.add_parser("review", help="review due cards in the terminal")
    p.add_argument("deck", nargs="?", help="sub-deck, e.g. DSA (default: all of Devlogs)")
    p.add_argument("--offline", action="store_true", help="don't sync before/after")
    p.set_defaults(fn=review)
    p = sub.add_parser("stats", help="due counts and retention")
    p.add_argument("-a", "--all", action="store_true", help="include decks outside Devlogs")
    p.set_defaults(fn=stats)
    p = sub.add_parser("new", help="new note in the vault (Inbox/) from a template, opened in $EDITOR")
    p.add_argument("-f", "--folder", help="vault folder (default Inbox)")
    p.add_argument("-t", "--template", default="topic", help="cards/templates/<name>.md: topic, problem, source")
    p.add_argument("title", nargs="*")
    p.set_defaults(fn=new)
    p = sub.add_parser("login", help="log in to AnkiWeb (once); the key goes to the keychain")
    p.set_defaults(fn=login)
    p = sub.add_parser("orphans", help="Anki notes whose card block was deleted from the vault")
    p.add_argument("--delete", action="store_true")
    p.set_defaults(fn=orphans)
    p = sub.add_parser("apy", help="run apy on this collection, e.g. `cards apy edit nid:123`")
    p.add_argument("rest", nargs=argparse.REMAINDER)
    p.set_defaults(fn=apy)

    args = ap.parse_args(argv)
    return args.fn(args) or 0


if __name__ == "__main__":
    sys.exit(main())
