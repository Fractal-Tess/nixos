"""Send Supermemory's LLM calls to the ChatGPT subscription, with a local fallback.

Supermemory takes a single OpenAI-compatible endpoint. Each request goes to
CLIProxyAPI first. If that errors, times out or returns no choices (the
subscription ran out, the proxy is down), the same request goes to the local
model behind llama-swap instead, and CLIProxyAPI is skipped for a cooldown so
every call does not wait on a dead upstream.

The router also fixes how the self-hosted server turns coding sessions into
memories (measured by replaying real sessions, 2026-10-25):

- The plugins append every turn to one document per session, and the server
  re-runs its memory agent over the whole document once per appended turn.
  Each run re-extracts what earlier runs saved, so memories pile up as
  reworded duplicates, and one pass over a whole session misses most facts.
  Here each run is given one new turn instead: the router fetches the session
  from the API, inlines the oldest turn no run has handled yet (with the
  session's opening request and the previous turn as context), and records it
  once the run finishes. A run with nothing new is answered here without a
  model. Documents that are not sessions only have their already-seen chunks
  replaced with a stub.
- The server's extraction rules are written for personal chat (counts, scores,
  status changes), which fills coding memory with noise. For the primary model
  they get a list of what not to save in a coding project and a reminder not to
  save what is already stored ("hybrid"; replacing them outright lost too many
  facts), plus the two accuracy lines that scored best in the benchmark. The
  local model scored worse with extra rules and keeps the server's wording.
"""
import datetime
import hashlib
import json
import os
import re
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ["ROUTER_PORT"])
PRIMARY_URL = os.environ["PRIMARY_URL"]
PRIMARY_MODEL = os.environ["PRIMARY_MODEL"]
CREDENTIALS = os.environ["CREDENTIALS_DIRECTORY"]
PRIMARY_KEY = open(os.path.join(CREDENTIALS, "primary-key")).read().strip()
PRIMARY_TIMEOUT = int(os.environ.get("PRIMARY_TIMEOUT", "300"))
FALLBACK_URL = os.environ["FALLBACK_URL"]
FALLBACK_MODEL = os.environ["FALLBACK_MODEL"]
COOLDOWN = int(os.environ.get("COOLDOWN", "600"))
SUPERMEMORY_URL = os.environ.get("SUPERMEMORY_URL", "http://127.0.0.1:6767")
SUPERMEMORY_KEY_FILE = os.environ.get("SUPERMEMORY_KEY_FILE", os.path.join(CREDENTIALS, "supermemory-key"))
EXTRACTION_RULES = os.environ.get("EXTRACTION_RULES", "hybrid")  # "coding" replaces the server's rules, "server" keeps them
STATE_DIR = os.environ.get("ROUTER_STATE") or os.environ.get("STATE_DIRECTORY") or "."

RULES_END = "- Granular details that do not help future work"
ACCURACY = (
    "\nACCURACY:\n"
    "- Only record what the session actually states; never guess versions, paths, names or reasons it does not give\n"
    "- Name the project or tool in each memory so it makes sense on its own"
)
# Failures that mean the upstream is unusable for a while, not that this one request was bad.
OUTAGE_STATUSES = {401, 402, 403, 408, 429}

primary_down_until = [0.0]

#============================================================================
# MEMORY AGENT RUNS
#============================================================================
AGENT_SYSTEM = "You are a memory extraction agent."
CHUNK_RE = re.compile(r'<chunk position="(\d+)">\n(.*?)\n</chunk>', re.S)
TURN_RE = re.compile(r"<\|turn_start\|>(\S+)(.*?)<\|turn_end\|>", re.S)
STUB = "[already extracted in an earlier run]"
# Small turns are batched into one run; a turn this long is never cut.
TURN_BATCH_CHARS = 4000
CONTEXT_CHARS = 2500

CODING_RULES = """Save every durable fact from the new content below that a future coding session in this project would need and could not easily get from the code or git history. Make each memory a single fact: split anything compound into separate memories.

Workflow:
1. {read}
2. Before creating anything, call searchMemories for the topics you found.
3. If an existing memory already says it, even in other words, do not create it again. If the new content changes or corrects an existing memory, use CreateMemory with an "updates" parentRelation to it (or forgetMemory and a new CreateMemory when the old one is simply wrong now).
4. Otherwise CreateMemory for each new durable fact.

Save:
- User preferences and instructions, including how the user wants work done (commits, reviews, style)
- Decisions and the reasons for them
- Architecture, conventions, file locations and how the pieces fit together
- How to build, run, deploy and test the project, and the commands for it
- Pitfalls: things that broke and why, and what to avoid
- Plans and open work the user wants to come back to

Do not save:
- Status at a point in time: what version is installed, that an input is at its latest commit, that a check, build, rebuild or deploy passed, counts and sizes
- Test, CI or verification results
- Commit hashes, diffs, or anything else git and lockfiles already record
- One-off command output, and the assistant's own explanations
- Facts that only describe this session ("the user asked about X")

Each memory is one standalone sentence stating one fact and naming the project or tool it is about. When a memory is about a dated decision, incident or plan, set CreateMemory.temporalContext.eventDate to its YYYY-MM-DD date; otherwise leave temporalContext out. When the new content adds nothing durable, create nothing.

"""

os.makedirs(STATE_DIR, exist_ok=True)
ledger_lock = threading.Lock()
ledger_file = os.path.join(STATE_DIR, "extracted.json")
try:
    ledger = json.load(open(ledger_file))
except (OSError, ValueError):
    ledger = {}  # document key -> {"turns": [turn digests], "chunks": [chunk digests], "readTo": n}
runs = {}  # (original prompt digest, rules) -> the plan for that run
runs_lock = threading.Lock()


def squash(text):
    return re.sub(r"\s+", "", text)


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()[:24]


def save_ledger():
    tmp = ledger_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(ledger, f)
    os.replace(tmp, ledger_file)


def supermemory(path, body=None):
    key = open(SUPERMEMORY_KEY_FILE).read().strip()
    req = urllib.request.Request(SUPERMEMORY_URL + path, data=json.dumps(body).encode() if body is not None else None,
                                 method="POST" if body is not None else "GET",
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def session_content(title, first_chunk):
    """Full text of the document a run is about, found by its title among recently updated documents."""
    listed = supermemory("/v3/documents/list", {"limit": 50, "sort": "updatedAt", "order": "desc"})
    for doc in listed.get("memories", []):
        # The prompt shows the title's first line only, which for a session is its opening timestamp.
        if not squash(doc.get("title") or "").startswith(squash(title)):
            continue
        content = supermemory(f"/v3/documents/{doc['id']}").get("content") or ""
        # Chunks are stored with whitespace collapsed, so compare without it.
        if squash(content).startswith(squash(first_chunk)[:200]):
            return content
    return None


SKIP_RULES = """
This is a coding session: memories are for future coding sessions in the same project.
Before creating a memory, check the searchMemories results: if an existing memory already says it, even in other words, do not create it again.
Do not save:
- Status at a point in time: what version is installed, that an input is at its latest commit, that a check, build, rebuild or deploy passed, counts and sizes
- Test, CI or verification results
- Commit hashes, diffs, or anything else git and lockfiles already record
- One-off command output, and the assistant's own explanations
Name the project or tool in each memory.

"""


def session_key(turns):
    """Identify a session by its opening turn, so the key does not depend on how the server chunked it."""
    return "session:" + digest(turns[0][0] + squash(turns[0][1])[:500])


def adopt_existing():
    """First start: mark the turns of sessions already in the store as handled, since the server processed them
    before this router existed. Turns from the last 30 minutes may still be waiting in a batch and stay pending."""
    cutoff = time.time() - 1800
    adopted, page = {}, 1
    while True:
        listed = supermemory("/v3/documents/list", {"limit": 100, "page": page})
        for doc in listed.get("memories", []):
            if not (doc.get("title") or "").startswith("<|turn_start|>"):
                continue
            content = supermemory(f"/v3/documents/{doc['id']}").get("content") or ""
            turns = TURN_RE.findall(content)
            if not turns:
                continue
            keys = [digest(ts + text) for ts, text in turns if parse_time(ts) < cutoff]
            adopted[session_key(turns)] = {"turns": sorted(keys)}
        if page >= (listed.get("pagination") or {}).get("totalPages", 1):
            break
        page += 1
    with ledger_lock:
        for key, value in adopted.items():
            ledger.setdefault(key, value)
        save_ledger()
    print(f"adopted {len(adopted)} existing sessions", flush=True)


def parse_time(ts):
    try:
        return datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return time.time()


def rules(read, rewrite):
    return CODING_RULES.format(read=read) if rewrite else None


def hybrid(body, read):
    """The server's own extraction rules, with the read step swapped and the coding skip list added."""
    body = re.sub(r"^(\s*)1\. .*$", lambda m: m.group(1) + "1. " + read, body, count=1, flags=re.M)
    head, rest = body.split("Profile buckets:", 1)
    return head + SKIP_RULES + "Profile buckets:" + rest


def plan_session(prompt, doc, title, chunks, rewrite):
    """One run per new turn: inline the oldest unhandled turn(s) of a plugin session."""
    content = session_content(title, chunks[0])
    turns = [(ts, text) for ts, text in TURN_RE.findall(content or "")]
    if not turns:
        return None
    doc = session_key(turns)
    with ledger_lock:
        done = set(ledger.get(doc, {}).get("turns", []))
    keys = [digest(ts + text) for ts, text in turns]
    pending = [i for i, k in enumerate(keys) if k not in done]
    run = {"doc": doc, "kind": "turns", "started": time.time(), "skip": not pending, "prompt": prompt}
    if not pending:
        return run
    picked = [pending[0]]
    for i in pending[1:]:
        if i != picked[-1] + 1 or sum(len(turns[j][1]) for j in picked) + len(turns[i][1]) > TURN_BATCH_CHARS:
            break
        picked.append(i)
    run["keys"] = [keys[i] for i in picked]

    def block(i, limit=None):
        ts, text = turns[i]
        text = text.strip()
        if limit and len(text) > limit:
            text = text[:limit] + "\n[...]"
        return f"<|turn_start|>{ts}\n{text}\n<|turn_end|>"

    context = []
    if picked[0] > 0:
        context.append(block(0, CONTEXT_CHARS))
    if picked[0] > 1:
        context.append(block(picked[0] - 1, CONTEXT_CHARS))
    read = "All new content is inlined below; do not call readChunks."
    if context:
        read += " The earlier turns shown as context were processed in previous runs: create nothing from them."
    section = ""
    if context:
        section += "Earlier in this session (context only):\n" + "\n\n".join(context) + "\n\n"
    section += "New content:\n" + "\n\n".join(block(i) for i in picked)

    # Swap the server's chunk section, its "Initial chunks ..." header included, for the turns.
    first = prompt.index("<chunk ")
    header = prompt.rfind("\n", 0, prompt.rfind("\n", 0, first))
    end = prompt.rindex("</chunk>") + len("</chunk>")
    body = prompt[:header] + "\n\n" + section + prompt[end:]
    if rewrite and EXTRACTION_RULES == "hybrid":
        body = hybrid(body, read)
    elif rewrite:
        _, rest = body.split("Profile buckets:", 1)
        body = rules(read, True) + "Profile buckets:" + rest
    else:
        body = re.sub(r"^(\s*)1\. .*$", lambda m: m.group(1) + "1. " + read, body, count=1, flags=re.M)
    run["rewritten"] = body
    return run


def plan_chunks(prompt, doc, chunks, total, rewrite):
    """Other documents: tell the agent which chunks are new and stub the ones seen before."""
    with ledger_lock:
        known = ledger.get(doc, {})
    seen = set(known.get("chunks", []))
    read_to = known.get("readTo", 0)
    fresh = [p for p, c in chunks.items() if digest(c) not in seen]
    tail_start = max(len(chunks), read_to - 1)
    has_tail = total > tail_start
    run = {"doc": doc, "kind": "chunks", "started": time.time(), "seen": {digest(c) for c in chunks.values()},
           "seenBefore": seen, "readTo": len(chunks), "skip": not fresh and not has_tail, "prompt": prompt}
    if run["skip"]:
        return run
    read = "Start with the inlined chunks that are new." if fresh else "None of the inlined chunks are new."
    if has_tail:
        read += f" Read positions {tail_start}..{total - 1} with readChunks before creating memories."
    if seen:
        read += f" Chunks marked {STUB} were processed in an earlier run: use them only as context and create nothing from them."

    def stub(match):
        position, content = int(match.group(1)), match.group(2)
        if digest(content) in seen and position > 0:
            return f'<chunk position="{position}">\n{STUB}\n</chunk>'
        return match.group(0)

    body = CHUNK_RE.sub(stub, prompt)
    if rewrite and EXTRACTION_RULES == "hybrid":
        body = hybrid(body, read)
    elif rewrite:
        _, rest = body.split("Profile buckets:", 1)
        body = rules(read, True) + "Profile buckets:" + rest
    else:
        body = re.sub(r"^(\s*)1\. .*$", lambda m: m.group(1) + "1. " + read, body, count=1, flags=re.M)
    run["rewritten"] = body
    return run


def start_run(prompt, rewrite):
    """Plan a memory-agent run from the server's prompt; None when it does not look like one."""
    chunks = {int(p): c for p, c in CHUNK_RE.findall(prompt)}
    total = re.search(r"^\s*total chunks: (\d+)$", prompt, re.M)
    title = re.search(r"^\s*title: (.*)$", prompt, re.M)
    if not chunks or 0 not in chunks or not total or not title or "Profile buckets:" not in prompt:
        return None
    doc = digest(title.group(1) + "\n" + chunks[0])
    if chunks[0].startswith("<|turn_start|>"):
        try:
            run = plan_session(prompt, doc, title.group(1), chunks, rewrite)
            if run:
                print(f"run on {run['doc']}: {'nothing new' if run['skip'] else str(len(run['keys'])) + ' turn(s)'}", flush=True)
                return run
            print(f"run on {doc}: session not found, using chunks", flush=True)
        except Exception as e:  # the API is unreachable or the document moved: fall back to chunks
            print(f"session lookup failed, using chunks: {e!r}", flush=True)
    return plan_chunks(prompt, doc, chunks, int(total.group(1)), rewrite)


def apply_run(body, run):
    """Rewrite one request of a planned run: the prompt, and chunks returned by readChunks."""
    messages = body["messages"]
    messages[1]["content"] = run["rewritten"]
    if run["kind"] != "chunks":
        return
    for msg in messages[2:]:
        if msg.get("role") != "tool" or not isinstance(msg.get("content"), str):
            continue
        try:
            result = json.loads(msg["content"])
        except ValueError:
            continue
        if not isinstance(result, dict) or not isinstance(result.get("chunks"), list):
            continue
        for chunk in result["chunks"]:
            content = chunk.get("content")
            if not isinstance(content, str) or content == STUB:
                continue
            run["seen"].add(digest(content))
            if isinstance(chunk.get("position"), int):
                run["readTo"] = max(run["readTo"], chunk["position"] + 1)
            if digest(content) in run["seenBefore"]:
                chunk["content"] = STUB
        msg["content"] = json.dumps(result)


def finish_run(run):
    with ledger_lock:
        known = ledger.setdefault(run["doc"], {})
        if run["kind"] == "turns":
            known["turns"] = sorted(set(known.get("turns", [])) | set(run["keys"]))
        else:
            known["chunks"] = sorted(set(known.get("chunks", [])) | run["seen"])
            known["readTo"] = max(known.get("readTo", 0), run["readTo"])
        save_ledger()


def skipped_completion(model):
    return json.dumps({
        "id": "router-skip", "object": "chat.completion", "created": int(time.time()), "model": model,
        "choices": [{"index": 0, "finish_reason": "stop", "message": {
            "role": "assistant", "content": "Nothing was added since this document was last processed, so no memories were created."}}],
        "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    }).encode()


def plan(body, rewrite):
    """Return the run this request belongs to, or None for other calls."""
    messages = (body or {}).get("messages") or []
    system = messages[0].get("content") if messages else None
    if len(messages) < 2 or not isinstance(system, str) or not system.startswith(AGENT_SYSTEM) \
            or not isinstance(messages[1].get("content"), str):
        return None
    key = (digest(messages[1]["content"]), rewrite)
    with runs_lock:
        for stale in [k for k, v in runs.items() if time.time() - v["started"] > 3600]:
            del runs[stale]  # runs the server abandoned
        if key not in runs:
            planned = start_run(messages[1]["content"], rewrite)
            if planned is None:
                return None
            runs[key] = planned
        return runs[key]


def ends_run(data):
    try:
        message = json.loads(data)["choices"][0]["message"]
    except (ValueError, KeyError, IndexError, TypeError):
        return False
    return not message.get("tool_calls")


#============================================================================
# ROUTING
#============================================================================
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


def prepare(body, primary):
    """Copy the request for one upstream; returns it with the memory-agent run it belongs to."""
    if body is None:
        return None, None
    sent = json.loads(json.dumps(body))
    run = None
    try:
        run = plan(sent, rewrite=primary and EXTRACTION_RULES in ("coding", "hybrid"))
        if run and not run["skip"]:
            apply_run(sent, run)
    except Exception as e:  # never let the rewrite break a call; send it as the server wrote it
        print(f"memory-agent rewrite failed, sending unchanged: {e!r}", flush=True)
        sent, run = json.loads(json.dumps(body)), None
    if primary:
        add_accuracy_rules(sent)
    return sent, run


class Handler(BaseHTTPRequestHandler):
    def route(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(n)) if n else None
        path = self.path if self.path.startswith("/v1") else "/v1" + self.path
        t0 = time.time()
        status, data, served, run = None, b"", "primary", None
        if time.time() >= primary_down_until[0]:
            sent, run = prepare(body, primary=True)
            if run and run["skip"]:
                status, data, served, failed = 200, skipped_completion(PRIMARY_MODEL), "skipped", False
            else:
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
            sent, run = prepare(body, primary=False)
            if run and run["skip"]:
                status, data, served = 200, skipped_completion(FALLBACK_MODEL), "skipped"
            else:
                try:
                    status, data = call(FALLBACK_URL, path, sent, FALLBACK_MODEL, "", 900)
                except Exception as e:
                    status, data = 502, json.dumps({"error": {"message": f"both upstreams failed: {e}"}}).encode()
        if run and status == 200 and ends_run(data):
            if not run["skip"]:
                try:
                    finish_run(run)
                except Exception as e:  # the next run simply redoes this one's content
                    print(f"could not record finished run: {e!r}", flush=True)
            with runs_lock:
                runs.pop(next((k for k, v in runs.items() if v is run), None), None)
        print(f"{served} {path} {status} {time.time() - t0:.1f}s {usage(data)}", flush=True)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = route

    def log_message(self, *args):
        pass


if not os.path.exists(ledger_file):
    def adopt():
        for attempt in range(30):  # the server may still be starting
            try:
                return adopt_existing()
            except Exception as e:
                print(f"adopting existing sessions failed ({e!r}); retrying", flush=True)
                time.sleep(20)
    threading.Thread(target=adopt, daemon=True).start()

ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
