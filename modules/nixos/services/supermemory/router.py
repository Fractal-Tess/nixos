"""Send Supermemory's LLM calls to the ChatGPT subscription, with a local fallback.

Supermemory takes a single OpenAI-compatible endpoint. Each request goes to
CLIProxyAPI first. If that errors, times out or returns no choices (the
subscription ran out, the proxy is down), the same request goes to the local
model behind llama-swap instead, and CLIProxyAPI is skipped for a cooldown so
every call does not wait on a dead upstream.

The two accuracy lines that scored best in the 2026-10 benchmark are added to
the Supermemory plugin's extraction rules before they reach the primary model.
The local model scored worse with them, so it gets the rules unchanged.
"""
import json
import os
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ["ROUTER_PORT"])
PRIMARY_URL = os.environ["PRIMARY_URL"]
PRIMARY_MODEL = os.environ["PRIMARY_MODEL"]
PRIMARY_KEY = open(os.path.join(os.environ["CREDENTIALS_DIRECTORY"], "primary-key")).read().strip()
PRIMARY_TIMEOUT = int(os.environ.get("PRIMARY_TIMEOUT", "120"))
FALLBACK_URL = os.environ["FALLBACK_URL"]
FALLBACK_MODEL = os.environ["FALLBACK_MODEL"]
COOLDOWN = int(os.environ.get("COOLDOWN", "600"))

RULES_END = "- Granular details that do not help future work"
ACCURACY = (
    "\nACCURACY:\n"
    "- Only record what the session actually states; never guess versions, paths, names or reasons it does not give\n"
    "- Name the project or tool in each memory so it makes sense on its own"
)
# Failures that mean the upstream is unusable for a while, not that this one request was bad.
OUTAGE_STATUSES = {401, 402, 403, 408, 429}

primary_down_until = [0.0]


def add_accuracy_rules(body):
    for msg in body.get("messages", []):
        text = msg.get("content")
        if isinstance(text, str) and RULES_END in text and "ACCURACY:" not in text:
            msg["content"] = text.replace(RULES_END, RULES_END + ACCURACY, 1)


def call(url, path, body, model, key, timeout):
    data = json.dumps({**body, "model": model}).encode() if body is not None else None
    req = urllib.request.Request(url + path, data=data, method="POST" if data else "GET")
    req.add_header("Content-Type", "application/json")
    if key:
        req.add_header("Authorization", f"Bearer {key}")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def usable(path, status, data):
    if status != 200:
        return False
    if not path.endswith("/chat/completions"):
        return True
    try:
        return bool(json.loads(data).get("choices"))
    except ValueError:
        return False


def usage(data):
    try:
        u = json.loads(data).get("usage") or {}
    except ValueError:
        return ""
    cached = (u.get("prompt_tokens_details") or {}).get("cached_tokens") or 0
    return f"in={u.get('prompt_tokens', 0)} cached={cached} out={u.get('completion_tokens', 0)}"


class Handler(BaseHTTPRequestHandler):
    def route(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(n)) if n else None
        path = self.path if self.path.startswith("/v1") else "/v1" + self.path
        t0 = time.time()
        status, data, served = None, b"", "primary"
        if time.time() >= primary_down_until[0]:
            sent = json.loads(json.dumps(body)) if body is not None else None
            if sent is not None:
                add_accuracy_rules(sent)
            try:
                status, data = call(PRIMARY_URL, path, sent, PRIMARY_MODEL, PRIMARY_KEY, PRIMARY_TIMEOUT)
                failed = not usable(path, status, data)
            except Exception as e:  # connection refused, timeout, reset
                status, data, failed = None, str(e).encode(), True
            if failed:
                outage = status is None or status >= 500 or status in OUTAGE_STATUSES
                if outage:
                    primary_down_until[0] = time.time() + COOLDOWN
                print(f"primary failed ({status}): {data[:200]!r}; "
                      f"{'skipping it for ' + str(COOLDOWN) + 's' if outage else 'retrying on fallback'}", flush=True)
        else:
            failed = True
        if failed:
            served = "fallback"
            try:
                status, data = call(FALLBACK_URL, path, body, FALLBACK_MODEL, "", 900)
            except Exception as e:
                status, data = 502, json.dumps({"error": {"message": f"both upstreams failed: {e}"}}).encode()
        print(f"{served} {path} {status} {time.time() - t0:.1f}s {usage(data)}", flush=True)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = route

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
