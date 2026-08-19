#!/usr/bin/env python3
"""Tests for scripts/mail_fetch.py that need no mailbox and no network.

Covers the parts that fail silently: MIME decoding, multi-account config
parsing, password normalisation and the on-disk cache.
"""

import email
import importlib.util
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

WORK = tempfile.mkdtemp(prefix="zenith-mail-test-")
os.environ["ZENITH_MAIL_CACHE"] = os.path.join(WORK, "cache")
os.environ["ZENITH_MAIL_CONFIG"] = os.path.join(WORK, "mail.json")

spec = importlib.util.spec_from_file_location(
    "mail_fetch", os.path.join(REPO, "scripts", "mail_fetch.py"))
mf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mf)

results = []


def ok(cond, msg):
    print(("  PASS  " if cond else "  FAIL  ") + msg)
    results.append(bool(cond))


PLAIN = b"""From: A <a@x.com>\r
Subject: Hi\r
Content-Type: multipart/mixed; boundary="B"\r
\r
--B\r
Content-Type: text/plain; charset="utf-8"\r
\r
Hello there.\r
Second line.\r
--B\r
Content-Type: application/pdf\r
Content-Disposition: attachment; filename="report.pdf"\r
\r
JVBERi0=\r
--B--\r
"""

HTML = b"""From: B <b@x.com>\r
Subject: Newsletter\r
Content-Type: text/html; charset="utf-8"\r
\r
<html><head><style>p{color:red}</style></head><body>\r
<h1>Sale</h1><p>Fifty percent off &amp; free shipping</p>\r
<script>evil()</script><div>Ends Friday</div></body></html>\r
"""

ENCODED = b"""From: =?utf-8?B?SsO2cmc=?= <j@x.com>\r
Subject: =?utf-8?B?Q2Fmw6k=?=\r
Content-Type: text/plain; charset="iso-8859-1"\r
\r
caf\xe9 na\xefve\r
"""


def main():
    # --- MIME ---
    body, was_html, atts = mf.extract_body(email.message_from_bytes(PLAIN))
    ok(body == "Hello there.\nSecond line.", "plain text body extracted")
    ok(atts == ["report.pdf"], "attachment listed, not inlined")
    ok(was_html is False, "plain mail not flagged as html")

    body, was_html, atts = mf.extract_body(email.message_from_bytes(HTML))
    ok("evil()" not in body and "color:red" not in body,
       "script and style stripped from html mail")
    ok("Fifty percent off & free shipping" in body, "html entities unescaped")
    ok(was_html is True, "html mail flagged")

    msg = email.message_from_bytes(ENCODED)
    ok(mf.decode(msg.get("From")).startswith("Jörg"), "encoded header decoded")
    body, _, _ = mf.extract_body(msg)
    ok("café naïve" in body, "iso-8859-1 body decoded")

    # --- config ---
    single = {"host": "imap.gmail.com", "user": "one@x.com", "password": "a b c d"}
    with open(os.environ["ZENITH_MAIL_CONFIG"], "w") as f:
        json.dump(single, f)
    accounts, err = mf.load_accounts()
    ok(err is None and len(accounts) == 1, "legacy single-account file accepted")
    ok(accounts[0]["password"] == "abcd", "app password whitespace stripped")

    multi = {"accounts": [
        {"user": "work@x.com", "password": "p1"},
        {"user": "home@y.com", "password": "p2", "host": "imap.y.com"}]}
    with open(os.environ["ZENITH_MAIL_CONFIG"], "w") as f:
        json.dump(multi, f)
    accounts, err = mf.load_accounts()
    ok(len(accounts) == 2, "multi-account file accepted")
    ok(mf.pick(accounts, "home")["user"] == "home@y.com", "account selected by name")
    ok(mf.pick(accounts, "1")["user"] == "home@y.com", "account selected by index")
    ok(mf.pick(accounts, None)["user"] == "work@x.com", "first account is the default")

    # --- cache ---
    cfg = accounts[0]
    ok(mf.read_cache(cfg) is None, "no cache before the first fetch")
    mf.write_cache(cfg, {"unread": 2, "user": cfg["user"],
                         "messages": [{"uid": "9", "subject": "Hi"}]})
    got = mf.read_cache(cfg)
    ok(got and got["unread"] == 2 and len(got["messages"]) == 1,
       "cache round-trips so the tab can paint before the network answers")

    # --- broken config must not raise ---
    with open(os.environ["ZENITH_MAIL_CONFIG"], "w") as f:
        f.write("not json")
    accounts, err = mf.load_accounts()
    ok(accounts == [] and err, "malformed config reports an error instead of raising")

    print("\n  %d/%d passed" % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
