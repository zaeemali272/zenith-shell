"""In-process stand-in for the Todoist API v1, for todoist_sync_test.py.

Only the endpoints scripts/todoist_sync.py actually calls, with the same
response shapes: paginated {"results": [...], "next_cursor": null} for reads,
the created object for writes.
"""

import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 8477
STATE = {"projects": [], "tasks": [], "next": 1}


def reset():
    STATE["projects"] = []
    STATE["tasks"] = []
    STATE["next"] = 1


def _new_id(prefix):
    STATE["next"] += 1
    return "%s%d" % (prefix, STATE["next"])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _path(self):
        return self.path.split("?")[0]

    def do_GET(self):
        p = self._path()
        if p == "/projects":
            self._send({"results": STATE["projects"], "next_cursor": None})
        elif p == "/tasks":
            active = [t for t in STATE["tasks"] if not t.get("is_completed")]
            self._send({"results": active, "next_cursor": None})
        else:
            self._send({"error": "not found"}, 404)

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(n) or b"{}")

    def do_POST(self):
        p = self._path()
        if p == "/projects":
            proj = {"id": _new_id("p"), "name": self._body().get("name", "")}
            STATE["projects"].append(proj)
            self._send(proj)
        elif p == "/tasks":
            b = self._body()
            task = {"id": _new_id("t"), "content": b.get("content", ""),
                    "project_id": b.get("project_id"), "is_completed": False}
            STATE["tasks"].append(task)
            self._send(task)
        elif p.endswith("/close") or p.endswith("/reopen"):
            tid = p.split("/")[2]
            for t in STATE["tasks"]:
                if t["id"] == tid:
                    t["is_completed"] = p.endswith("/close")
            self._send({})
        elif p.startswith("/tasks/"):
            tid = p.split("/")[2]
            b = self._body()
            for t in STATE["tasks"]:
                if t["id"] == tid and "content" in b:
                    t["content"] = b["content"]
            self._send({})
        else:
            self._send({"error": "not found"}, 404)

    def do_DELETE(self):
        p = self._path()
        if p.startswith("/tasks/"):
            tid = p.split("/")[2]
            STATE["tasks"] = [t for t in STATE["tasks"] if t["id"] != tid]
            self._send({})
        else:
            self._send({"error": "not found"}, 404)


def serve():
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server
