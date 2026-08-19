#!/usr/bin/env python3
"""IMAP mail reader for the Zenith shell.

Reads the newest messages from an IMAP mailbox and prints them as JSON. Uses
only the standard library (imaplib, email, ssl), so there is nothing to install.

Credentials live at ~/.config/zenith/mail.json, owner-readable only, separate
from anything the UI writes:

    {"host": "imap.gmail.com", "port": 993,
     "user": "you@gmail.com", "password": "<app password>",
     "mailbox": "INBOX"}

Gmail needs an App Password (2-step verification must be on); the account
password will not authenticate over IMAP. https://myaccount.google.com/apppasswords

Commands:
    mail_fetch.py status          connection state + unread count
    mail_fetch.py list [N]        newest N messages (default 20)
    mail_fetch.py body <uid>      full text of one message
    mail_fetch.py read <uid>      mark one message seen
"""

import email
import email.policy
import email.utils
import html
import html.parser
import imaplib
import json
import os
import socket
import ssl
import sys
from email.header import decode_header, make_header

HOME = os.path.expanduser("~")
CONFIG = os.environ.get(
    "ZENITH_MAIL_CONFIG", os.path.join(HOME, ".config", "zenith", "mail.json"))
TIMEOUT = 20


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def load_config():
    try:
        with open(CONFIG, encoding="utf-8") as f:
            cfg = json.load(f)
    except FileNotFoundError:
        return None, "No mail account configured."
    except Exception as e:
        return None, "Config is not valid JSON: %s" % e

    if not cfg.get("user") or not cfg.get("password"):
        return None, "Config is missing user or password."
    cfg["password"] = "".join(str(cfg["password"]).split())
    cfg.setdefault("host", "imap.gmail.com")
    cfg.setdefault("port", 993)
    cfg.setdefault("mailbox", "INBOX")
    return cfg, None


def decode(raw):
    """MIME-encoded headers -> readable text, without ever raising."""
    if not raw:
        return ""
    try:
        return str(make_header(decode_header(raw))).strip()
    except Exception:
        return str(raw).strip()


class _HtmlText(html.parser.HTMLParser):
    """Bare-minimum HTML to text.

    Plenty of mail is HTML-only. Rendering it properly is out of scope for a
    shell panel, but showing raw tags is useless, so script/style are dropped
    and block elements become line breaks.
    """

    SKIP = {"script", "style", "head", "title"}
    BREAK = {"p", "div", "br", "tr", "li", "h1", "h2", "h3", "h4", "table"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self._skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self._skip += 1
        elif tag in self.BREAK:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP and self._skip:
            self._skip -= 1
        elif tag in self.BREAK:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self._skip:
            self.parts.append(data)

    def text(self):
        out = "".join(self.parts)
        lines = [ln.strip() for ln in out.splitlines()]
        cleaned, blank = [], 0
        for ln in lines:
            if ln:
                cleaned.append(ln)
                blank = 0
            else:
                blank += 1
                if blank < 2:
                    cleaned.append("")
        return "\n".join(cleaned).strip()


def part_text(part):
    """Decoded text of one MIME part, never raising on a bad charset."""
    payload = part.get_payload(decode=True)
    if payload is None:
        return ""
    charset = part.get_content_charset() or "utf-8"
    try:
        return payload.decode(charset, errors="replace")
    except (LookupError, TypeError):
        return payload.decode("utf-8", errors="replace")


def extract_body(msg, limit=120000):
    """(text, was_html, [attachment names]) for a parsed message."""
    plain, htmls, attachments = [], [], []

    for part in msg.walk():
        if part.get_content_maintype() == "multipart":
            continue
        disp = str(part.get("Content-Disposition") or "")
        filename = part.get_filename()
        if filename or "attachment" in disp.lower():
            if filename:
                attachments.append(decode(filename))
            continue

        ctype = part.get_content_type()
        if ctype == "text/plain":
            plain.append(part_text(part))
        elif ctype == "text/html":
            htmls.append(part_text(part))

    was_html = False
    if any(p.strip() for p in plain):
        body = "\n".join(plain)
    elif htmls:
        parser = _HtmlText()
        try:
            parser.feed("\n".join(htmls))
            body = parser.text()
        except Exception:
            body = "\n".join(htmls)
        was_html = True
    else:
        body = ""

    body = body.replace("\r\n", "\n").replace("\r", "\n").strip()
    if len(body) > limit:
        body = body[:limit] + "\n\n[... truncated]"
    return body, was_html, attachments


def connect(cfg):
    ctx = ssl.create_default_context()
    conn = imaplib.IMAP4_SSL(cfg["host"], int(cfg["port"]),
                             ssl_context=ctx, timeout=TIMEOUT)
    conn.login(cfg["user"], cfg["password"])
    return conn


def fetch(cfg, limit):
    conn = connect(cfg)
    try:
        conn.select(cfg["mailbox"], readonly=True)

        # UIDs, not sequence numbers: sequence numbers shift as the mailbox
        # changes, so marking one read later could hit the wrong message.
        typ, data = conn.uid("search", None, "ALL")
        if typ != "OK" or not data or not data[0]:
            return [], 0
        uids = data[0].split()[-limit:]
        uids.reverse()

        typ, unseen = conn.uid("search", None, "UNSEEN")
        unread = len(unseen[0].split()) if typ == "OK" and unseen and unseen[0] else 0

        # Headers only, plus flags. Bodies would be megabytes for no gain -- the
        # list only shows sender, subject and date.
        items = []
        for uid in uids:
            typ, msg_data = conn.uid(
                "fetch", uid,
                "(FLAGS BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)])")
            if typ != "OK" or not msg_data:
                continue

            flags, raw = b"", b""
            for part in msg_data:
                if isinstance(part, tuple):
                    flags = flags or part[0]
                    raw = part[1]
                elif isinstance(part, bytes):
                    flags += part

            msg = email.message_from_bytes(raw)
            from_raw = decode(msg.get("From"))
            name, addr = email.utils.parseaddr(from_raw)

            date_raw = msg.get("Date")
            try:
                ts = int(email.utils.parsedate_to_datetime(date_raw).timestamp())
            except Exception:
                ts = 0

            items.append({
                "uid": uid.decode("ascii", "ignore"),
                "from": name or addr or from_raw or "(unknown)",
                "addr": addr,
                "subject": decode(msg.get("Subject")) or "(no subject)",
                "ts": ts,
                "unread": b"\\Seen" not in flags,
            })
        return items, unread
    finally:
        try:
            conn.logout()
        except Exception:
            pass


def classify(e):
    """Split "wrong password" from "no network" -- the user can only act on one."""
    if isinstance(e, imaplib.IMAP4.error):
        text = str(e).lower()
        if "application-specific" in text or "app password" in text:
            return "auth", ("Gmail needs an App Password, not your account "
                            "password. Create one at "
                            "myaccount.google.com/apppasswords")
        return "auth", "Mail server rejected these credentials."
    if isinstance(e, (socket.gaierror, socket.timeout, TimeoutError, OSError, ssl.SSLError)):
        return "offline", "Could not reach the mail server."
    return "error", str(e)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    cfg, err = load_config()

    if cfg is None:
        emit({"type": "error", "message": err, "needs_config": True})
        return

    try:
        if cmd == "status":
            items, unread = fetch(cfg, 1)
            emit({"type": "status", "connected": True,
                  "unread": unread, "user": cfg["user"]})

        elif cmd == "list":
            limit = 20
            if len(sys.argv) > 2:
                try:
                    limit = max(1, min(100, int(sys.argv[2])))
                except ValueError:
                    pass
            items, unread = fetch(cfg, limit)
            emit({"type": "list", "unread": unread,
                  "user": cfg["user"], "messages": items})

        elif cmd == "body":
            if len(sys.argv) < 3:
                emit({"type": "error", "message": "body needs a uid"})
                return
            uid = sys.argv[2]
            conn = connect(cfg)
            try:
                conn.select(cfg["mailbox"], readonly=True)
                typ, data = conn.uid("fetch", uid, "(BODY.PEEK[])")
                raw = b""
                for part in data or []:
                    if isinstance(part, tuple):
                        raw = part[1]
                if typ != "OK" or not raw:
                    emit({"type": "error", "message": "Message not found."})
                    return
                msg = email.message_from_bytes(raw)
                body, was_html, attachments = extract_body(msg)
                emit({
                    "type": "body",
                    "uid": uid,
                    "from": decode(msg.get("From")),
                    "to": decode(msg.get("To")),
                    "subject": decode(msg.get("Subject")) or "(no subject)",
                    "date": decode(msg.get("Date")),
                    "message_id": (msg.get("Message-Id") or "").strip().strip("<>"),
                    "html": was_html,
                    "attachments": attachments,
                    "body": body,
                })
            finally:
                try:
                    conn.logout()
                except Exception:
                    pass

        elif cmd == "read":
            if len(sys.argv) < 3:
                emit({"type": "error", "message": "read needs a uid"})
                return
            conn = connect(cfg)
            try:
                conn.select(cfg["mailbox"])
                conn.uid("store", sys.argv[2], "+FLAGS", "(\\Seen)")
            finally:
                try:
                    conn.logout()
                except Exception:
                    pass
            emit({"type": "read_done", "uid": sys.argv[2]})

        else:
            emit({"type": "error", "message": "unknown command: %s" % cmd})

    except Exception as e:  # noqa: BLE001 - a mail failure must not kill the tab
        kind, message = classify(e)
        emit({"type": "error", "message": message,
              "auth": kind == "auth", "offline": kind == "offline"})


if __name__ == "__main__":
    main()
