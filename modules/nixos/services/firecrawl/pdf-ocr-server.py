#!/usr/bin/env python3
import base64
import json
import os
import re
import subprocess
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8080"))
MAX_REQUEST_BYTES = int(os.environ.get("MAX_REQUEST_BYTES", str(42 * 1024 * 1024)))
MAX_PDF_BYTES = int(os.environ.get("MAX_PDF_BYTES", str(30 * 1024 * 1024)))
MAX_PAGES = int(os.environ.get("MAX_PAGES", "50"))
MAX_CONCURRENT = int(os.environ.get("MAX_CONCURRENT", "1"))
PAGE_TIMEOUT_SECONDS = int(os.environ.get("PAGE_TIMEOUT_SECONDS", "45"))
DEFAULT_DEADLINE_SECONDS = int(os.environ.get("DEFAULT_DEADLINE_SECONDS", "300"))
OCR_DPI = int(os.environ.get("OCR_DPI", "250"))
OCR_LANGUAGE = os.environ.get("OCR_LANGUAGE", "eng")
MIN_NATIVE_TEXT_CHARACTERS = int(os.environ.get("MIN_NATIVE_TEXT_CHARACTERS", "40"))

semaphore = threading.BoundedSemaphore(MAX_CONCURRENT)


def run(command, timeout, text=True):
    return subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=text,
        timeout=max(1, timeout),
        env={**os.environ, "OMP_THREAD_LIMIT": "1"},
    )


def remaining_seconds(deadline):
    return max(1, min(PAGE_TIMEOUT_SECONDS, int(deadline - time.monotonic())))


def normalize_text(value):
    value = value.replace("\x00", "")
    value = re.sub(r"[ \t]+\n", "\n", value)
    value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip()


def pdf_page_count(path, deadline):
    result = run(["pdfinfo", str(path)], remaining_seconds(deadline))
    match = re.search(r"^Pages:\s+(\d+)\s*$", result.stdout, re.MULTILINE)
    if not match:
        raise RuntimeError("pdfinfo did not report a page count")
    return int(match.group(1))


def native_page_text(path, page, deadline):
    result = run(
        ["pdftotext", "-f", str(page), "-l", str(page), "-layout", "-nopgbrk", str(path), "-"],
        remaining_seconds(deadline),
    )
    return normalize_text(result.stdout)


def ocr_page(path, page, workdir, deadline):
    prefix = Path(workdir) / f"page-{page}"
    run(
        [
            "pdftoppm",
            "-f",
            str(page),
            "-l",
            str(page),
            "-r",
            str(OCR_DPI),
            "-png",
            "-singlefile",
            str(path),
            str(prefix),
        ],
        remaining_seconds(deadline),
    )
    image_path = prefix.with_suffix(".png")
    result = run(
        ["tesseract", str(image_path), "stdout", "-l", OCR_LANGUAGE, "--psm", "3"],
        remaining_seconds(deadline),
    )
    image_path.unlink(missing_ok=True)
    return normalize_text(result.stdout)


def parse_pdf(payload):
    encoded = payload.get("pdf")
    if not isinstance(encoded, str) or not encoded:
        raise ValueError("pdf must be a non-empty base64 string")
    try:
        pdf = base64.b64decode(encoded, validate=True)
    except Exception as error:
        raise ValueError("pdf is not valid base64") from error
    if len(pdf) > MAX_PDF_BYTES:
        raise ValueError("PDF exceeds the configured byte limit")
    if b"%PDF" not in pdf[:1024]:
        raise ValueError("input does not contain a PDF signature")

    requested_pages = payload.get("max_pages", MAX_PAGES)
    if not isinstance(requested_pages, int) or requested_pages < 1:
        raise ValueError("max_pages must be a positive integer")
    requested_pages = min(requested_pages, MAX_PAGES)
    mode = payload.get("mode", "auto")
    if mode not in ("auto", "ocr", "fast"):
        raise ValueError("mode must be auto, ocr, or fast")

    request_timeout_ms = payload.get("timeout")
    if isinstance(request_timeout_ms, (int, float)) and request_timeout_ms > 0:
        elapsed_ms = max(0, int(time.time() * 1000) - int(payload.get("created_at", int(time.time() * 1000))))
        deadline_seconds = max(1, min(DEFAULT_DEADLINE_SECONDS, (request_timeout_ms - elapsed_ms) / 1000))
    else:
        deadline_seconds = DEFAULT_DEADLINE_SECONDS
    deadline = time.monotonic() + deadline_seconds

    with tempfile.TemporaryDirectory(prefix="firecrawl-pdf-ocr-") as directory:
        pdf_path = Path(directory) / "input.pdf"
        pdf_path.write_bytes(pdf)
        total_pages = pdf_page_count(pdf_path, deadline)
        pages_to_process = min(total_pages, requested_pages)
        failed_pages = []
        sections = []

        for page in range(1, pages_to_process + 1):
            if time.monotonic() >= deadline:
                failed_pages.extend(range(page, pages_to_process + 1))
                break
            try:
                native_text = native_page_text(pdf_path, page, deadline)
                if mode == "fast":
                    text = native_text
                elif mode == "ocr" or len(re.sub(r"\s+", "", native_text)) < MIN_NATIVE_TEXT_CHARACTERS:
                    text = ocr_page(pdf_path, page, directory, deadline)
                else:
                    text = native_text
                if text:
                    sections.append(f"## Page {page}\n\n{text}")
                else:
                    failed_pages.append(page)
            except (subprocess.SubprocessError, OSError, RuntimeError):
                failed_pages.append(page)

        return {
            "markdown": "\n\n".join(sections),
            "failed_pages": failed_pages or None,
            "pages_processed": pages_to_process - len(failed_pages),
        }


class Handler(BaseHTTPRequestHandler):
    server_version = "FirecrawlPDFOCR/1.0"

    def log_message(self, format_string, *args):
        print(f"{self.address_string()} - {format_string % args}", flush=True)

    def respond(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path not in ("/", "/health"):
            return self.respond(404, {"error": "not found"})
        return self.respond(200, {"status": "ok", "active": MAX_CONCURRENT - semaphore._value})

    def do_POST(self):
        if self.path != "/ocr":
            return self.respond(404, {"error": "not found"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.respond(400, {"error": "invalid content length"})
        if length <= 0 or length > MAX_REQUEST_BYTES:
            return self.respond(413, {"error": "request body exceeds the configured limit"})
        if not semaphore.acquire(blocking=False):
            return self.respond(429, {"error": "PDF OCR worker is busy"})
        try:
            payload = json.loads(self.rfile.read(length))
            return self.respond(200, parse_pdf(payload))
        except ValueError as error:
            return self.respond(400, {"error": str(error)})
        except subprocess.TimeoutExpired:
            return self.respond(504, {"error": "PDF OCR deadline exceeded"})
        except Exception as error:
            print(f"PDF OCR failed: {error!r}", flush=True)
            return self.respond(500, {"error": "PDF OCR failed"})
        finally:
            semaphore.release()


if __name__ == "__main__":
    if not 1 <= PORT <= 65535:
        raise SystemExit("PORT must be between 1 and 65535")
    if MAX_CONCURRENT < 1 or MAX_PAGES < 1:
        raise SystemExit("MAX_CONCURRENT and MAX_PAGES must be positive")
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Firecrawl PDF OCR listening on {HOST}:{PORT}", flush=True)
    server.serve_forever()
