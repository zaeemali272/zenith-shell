#!/usr/bin/env python3
"""Behavioural tests for scripts/todoist_sync.py against a mock Todoist.

These exist because the sync has failure modes that look fine in review and
are destructive in practice -- dropping todoist_id duplicated an entire tab,
and treating a completed task as deleted removed it locally. Every case below
corresponds to a bug that actually shipped.
"""

import json
import os
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mock_todoist as M

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SCRIPT = os.path.join(REPO, "scripts", "todoist_sync.py")

WORK = tempfile.mkdtemp(prefix="zenith-todoist-test-")
TODO = os.path.join(WORK, "todo.json")
TOK = os.path.join(WORK, "token.json")

ENV = dict(os.environ,
           ZENITH_TODOIST_API="http://127.0.0.1:%d" % M.PORT,
           ZENITH_TODO_FILE=TODO,
           ZENITH_TODOIST_TOKEN_FILE=TOK)

results = []


def run(cmd="sync"):
    out = subprocess.run([sys.executable, SCRIPT, cmd], env=ENV,
                         capture_output=True, text=True).stdout.strip()
    return json.loads(out) if out else {}


def local():
    with open(TODO) as f:
        return json.load(f)


def write(data):
    with open(TODO, "w") as f:
        json.dump(data, f, indent=2)


def ok(cond, msg):
    print(("  PASS  " if cond else "  FAIL  ") + msg)
    results.append(bool(cond))
    return cond


def main():
    M.serve()
    time.sleep(0.4)
    with open(TOK, "w") as f:
        json.dump({"token": "good-token"}, f)

    # 1. Local-only work is pushed up.
    write([{"name": "Work", "tasks": [
        {"task": "write spec", "completed": False},
        {"task": "done thing", "completed": True}]}])
    r = run()
    ok(r.get("pushed") == 2, "2 local tasks pushed (got %s)" % r.get("pushed"))
    ok(len(M.STATE["projects"]) == 1 and M.STATE["projects"][0]["name"] == "Work",
       "tab became a Todoist project")
    ok(all(t.get("todoist_id") for t in local()[0]["tasks"]),
       "pushed tasks got todoist_ids")
    ok(any(t["is_completed"] for t in M.STATE["tasks"]), "completed state pushed")

    # 2. Remote-only work is pulled down.
    M.STATE["tasks"].append({"id": "9001", "content": "from phone",
                             "project_id": M.STATE["projects"][0]["id"],
                             "is_completed": False})
    r = run()
    ok(r.get("pulled") == 1, "remote task pulled (got %s)" % r.get("pulled"))
    ok(any(t["task"] == "from phone" for t in local()[0]["tasks"]),
       "pulled task present locally")

    # 3. Conflict: Todoist wins.
    tabs = local()
    target = next(t for t in tabs[0]["tasks"] if t["task"] == "from phone")
    target["task"] = "edited locally"
    write(tabs)
    run()
    ok(any(t["task"] == "from phone" for t in local()[0]["tasks"]),
       "conflict resolved in Todoist's favour")

    # 4. An edit marked dirty is pushed instead of being reverted.
    tabs = local()
    target = next(t for t in tabs[0]["tasks"] if t["task"] == "from phone")
    target["task"] = "offline edit"
    target["dirty"] = True
    write(tabs)
    r = run()
    ok(r.get("updated") == 1, "dirty edit pushed (updated=%s)" % r.get("updated"))
    ok(any(t["content"] == "offline edit" for t in M.STATE["tasks"]),
       "server has the offline edit")

    # 5. A tombstoned delete is replayed to the server.
    tabs = local()
    victim = tabs[0]["tasks"][0]
    victim["deleted"] = True
    vid = victim["todoist_id"]
    write(tabs)
    run()
    ok(not any(t["id"] == str(vid) for t in M.STATE["tasks"]),
       "offline delete removed from server")

    # 6. Deleted in Todoist disappears locally.
    before = len(local()[0]["tasks"])
    M.STATE["tasks"].pop()
    run()
    ok(len(local()[0]["tasks"]) < before, "remote deletion removed locally")

    # 7. A ticked task that Todoist has closed is kept, not deleted.
    tabs = local()
    tabs[0]["tasks"].append({"task": "ticked here", "completed": True,
                             "todoist_id": "7777", "deleted": False})
    write(tabs)
    run()
    ok(any(t.get("todoist_id") == "7777" for t in local()[0]["tasks"]),
       "completed task kept when absent from the active list")

    # 8. An empty remote project does not become a blank tab.
    M.STATE["projects"].append({"id": "p-empty", "name": "Empty Project"})
    run()
    ok(not any(t["name"] == "Empty Project" for t in local()),
       "empty remote project creates no tab")

    # 9. Offline leaves the file untouched.
    ENV["ZENITH_TODOIST_API"] = "http://127.0.0.1:9"
    snapshot = json.dumps(local(), sort_keys=True)
    r = run()
    ok(r.get("offline") is True, "offline reported as offline")
    ok(json.dumps(local(), sort_keys=True) == snapshot,
       "local file untouched while offline")

    print("\n  %d/%d passed" % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
