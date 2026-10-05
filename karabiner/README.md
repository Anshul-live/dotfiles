# Karabiner-Elements

`karabiner.json` is linked to `~/.config/karabiner/karabiner.json` by `install.sh`.
JSON has no comments, so the rules are explained here. They apply to every keyboard
(MacBook built-in and the Kreo Hive 65); everything else is stock.

| Key           | Tap     | Hold / with another key                              |
|---------------|---------|------------------------------------------------------|
| Caps Lock     | Escape  | Left Control                                         |
| Right Command | nothing | Hyper = Ctrl+Alt+Cmd (no Shift, so Hyper+Shift stays free for "move window") |

- Escape only fires if Caps is released within 200 ms (`basic.to_if_alone_timeout_milliseconds`),
  so holding Caps and changing your mind doesn't send a stray Esc.
- Right Command no longer acts as Command; use the left one.

## Config lives in the repo

Edit `karabiner.json` here, not in the GUI. Karabiner watches the file and reloads on save.
If you change anything in the Karabiner GUI it rewrites the file (through the symlink,
reformatted) - review with `git diff` and commit or discard.

## First run (manual, once)

Karabiner needs approvals in System Settings before it does anything:
- General -> Login Items & Extensions: allow the Karabiner driver extension
  (Driver Extensions / "Karabiner-VirtualHIDDevice-Manager").
- Privacy & Security -> Input Monitoring: allow `karabiner_grabber` and `karabiner_observer`.
- Open Karabiner-Elements once; confirm both keyboards show as enabled under Devices.
