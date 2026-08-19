# Tests

    tests/run.sh          static checks + unit tests. Runs anywhere; CI runs this.
    tests/run.sh --all    the above plus the headless smoke test.

## Why these exist

`qmllint` parses; it does not run anything. Every bug that has actually shipped
in this repo parsed cleanly:

| Bug | What it looked like | What it did |
|---|---|---|
| `SystemTray.items.length` | valid property access | always `undefined`, so the empty-state branch never ran |
| dismiss `MouseArea` under a `mask` | a normal click handler | could only fire *inside* the menu, closing it on every click |
| `SplitParser` on a JSON file | a working parser | blanked the todo list the moment the file was pretty-printed |
| `syncCurrentTasks` rebuilding rows | a tidy refactor | dropped `todoist_id`, duplicating a whole Todoist project |
| `except Exception: sleep(2)` | defensive error handling | swallowed `BrokenPipeError`, leaking a polling daemon per restart |
| `Repeater` over `ShapePath` | reasonable-looking QML | `Repeater` needs Item delegates, so no connectors drew at all |
| negative layer-shell margin | an offset | moved notifications off-screen where they could not be hovered |

None of those are syntax errors. They need something to run the code.

## What each file covers

- `todoist_sync_test.py` — push, pull, conflict resolution, offline queueing and
  replay, against `mock_todoist.py`. Every case maps to a bug that shipped.
- `mail_test.py` — MIME decoding (multipart, HTML-only, encoded headers,
  non-UTF-8 charsets), multi-account config parsing, password normalisation and
  the on-disk cache. Needs no mailbox and no network.
- `smoke.sh` — loads the shell in a nested headless Hyprland, opens every menu
  over IPC, and fails on a crash or a QML error. This is the only check that
  catches layout crashes and dead click handlers.

`smoke.sh` skips itself when it cannot start a compositor (a sandboxed shell or
a CI runner without the right capabilities), so it never fails for reasons
nobody can act on. Run it locally before pushing anything that touches a menu.
