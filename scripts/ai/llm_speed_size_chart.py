#!/usr/bin/env python3
"""Generate a simple SVG scatter chart for local LLM benchmark results.

Plots model size (GiB) vs:
- token generation speed (tg tokens/sec)
- prefill speed (pp tokens/sec)

Input is the benchmark summary.csv plus each per-model JSON result file.
No third-party Python packages required.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
from typing import Any


DEFAULT_RESULTS_DIR = Path("/mnt/vault/ai/models/llms/bench-results")
DEFAULT_OUTPUT = DEFAULT_RESULTS_DIR / "speed_vs_size.svg"
DEFAULT_DATA_CSV = DEFAULT_RESULTS_DIR / "speed_vs_size.csv"

PANEL_W = 720
PANEL_H = 520
MARGIN_L = 72
MARGIN_R = 20
MARGIN_T = 56
MARGIN_B = 52
GAP = 36
SVG_W = PANEL_W * 2 + GAP + 40
SVG_H = PANEL_H + 120

PALETTE = {
    "Qwen": "#1372d9",
    "Gemma": "#dd6b20",
    "Mistral": "#1f9d72",
    "Hermes": "#8a3ffc",
    "DeepSeek": "#d7263d",
    "Phi": "#6f42c1",
    "Other": "#4b5563",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--data-csv", type=Path, default=DEFAULT_DATA_CSV)
    return parser.parse_args()


def read_summary(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def family_for(model_id: str) -> str:
    if model_id.startswith("Qwen"):
        return "Qwen"
    if model_id.startswith("gemma"):
        return "Gemma"
    if model_id.startswith("Mistral"):
        return "Mistral"
    if model_id.startswith("Hermes"):
        return "Hermes"
    if model_id.startswith("DeepSeek"):
        return "DeepSeek"
    if model_id.startswith("phi"):
        return "Phi"
    return "Other"


def short_label(model_id: str) -> str:
    replacements = [
        ("-A3B-APEX-I-Quality", " 35B IQ"),
        ("-UD-Q4_K_XL", " XL"),
        ("-Q4_K_M", " Q4KM"),
        ("-Q6_K", " Q6K"),
        ("-Q6_K_XL", " Q6XL"),
        ("-A4B-it", " A4B"),
        ("-it", ""),
        ("-Instruct", " Inst"),
        ("-ultra-uncensored-heretic-v2", " Heretic"),
    ]
    label = model_id
    for src, dst in replacements:
        label = label.replace(src, dst)
    label = label.replace("Qwen3.6-", "Q3.6 ")
    label = label.replace("Qwen3.5-", "Q3.5 ")
    label = label.replace("Qwen2.5-", "Q2.5 ")
    label = label.replace("gemma-4-", "Gem4 ")
    label = label.replace("Hermes-3-Llama-3.1-", "Hermes ")
    label = label.replace("Mistral-Small-", "Mistral ")
    label = label.replace("DeepSeek-R1-Distill-Qwen-", "DS-R1 ")
    label = label.replace("phi-4", "phi-4")
    return " ".join(label.split())


def extract_model_size_gib(result: dict[str, Any]) -> float | None:
    probes = result.get("fit_sweep", {}).get("probes", {})
    for probe in probes.values():
        metrics = probe.get("metrics", {})
        for key in ("pp", "tg"):
            metric = metrics.get(key)
            if metric and metric.get("model_size"):
                return metric["model_size"] / (1024 ** 3)
    return None


def build_rows(results_dir: Path) -> list[dict[str, Any]]:
    rows = []
    summary_path = results_dir / "summary.csv"
    for row in read_summary(summary_path):
        if row.get("status") != "complete":
            continue
        result_path = Path(row["result_file"])
        result = load_json(result_path)
        size_gib = extract_model_size_gib(result)
        if size_gib is None:
            continue
        model_id = row["model_id"]
        rows.append(
            {
                "model_id": model_id,
                "label": short_label(model_id),
                "family": family_for(model_id),
                "color": PALETTE[family_for(model_id)],
                "size_gib": size_gib,
                "tg_tps": float(row["tg_avg_tps_last"]),
                "pp_tps": float(row["pp_avg_tps_last"]),
                "max_context_stable": int(row["max_context_stable"]) if row["max_context_stable"] else None,
            }
        )
    return rows


def write_plot_data_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "model_id",
        "label",
        "family",
        "size_gib",
        "tg_tps",
        "pp_tps",
        "max_context_stable",
    ]
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key) for key in fieldnames})


def nice_ticks(min_v: float, max_v: float, count: int = 5) -> list[float]:
    if min_v == max_v:
        return [min_v]
    span = max_v - min_v
    raw = span / max(1, count - 1)
    mag = 10 ** math.floor(math.log10(raw))
    norm = raw / mag
    if norm <= 1:
        step = 1 * mag
    elif norm <= 2:
        step = 2 * mag
    elif norm <= 5:
        step = 5 * mag
    else:
        step = 10 * mag
    start = math.floor(min_v / step) * step
    end = math.ceil(max_v / step) * step
    ticks = []
    value = start
    while value <= end + step * 0.5:
        ticks.append(round(value, 6))
        value += step
    return [t for t in ticks if min_v - step * 0.5 <= t <= max_v + step * 0.5]


def scale(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    if in_max == in_min:
        return (out_min + out_max) / 2
    frac = (value - in_min) / (in_max - in_min)
    return out_min + frac * (out_max - out_min)


def xml_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def render_panel(
    rows: list[dict[str, Any]],
    title: str,
    metric_key: str,
    x0: float,
    y0: float,
    x_min: float,
    x_max: float,
    y_min: float,
    y_max: float,
) -> str:
    plot_x0 = x0 + MARGIN_L
    plot_y0 = y0 + MARGIN_T
    plot_x1 = x0 + PANEL_W - MARGIN_R
    plot_y1 = y0 + PANEL_H - MARGIN_B
    plot_w = plot_x1 - plot_x0
    plot_h = plot_y1 - plot_y0

    x_ticks = nice_ticks(x_min, x_max, 6)
    y_ticks = nice_ticks(y_min, y_max, 6)

    parts = [
        f'<text x="{x0 + 12}" y="{y0 + 28}" font-size="22" font-weight="700" fill="#111827">{xml_escape(title)}</text>',
        f'<rect x="{x0}" y="{y0}" width="{PANEL_W}" height="{PANEL_H}" rx="18" fill="#ffffff" stroke="#d1d5db"/>',
        f'<line x1="{plot_x0}" y1="{plot_y1}" x2="{plot_x1}" y2="{plot_y1}" stroke="#111827" stroke-width="1.5"/>',
        f'<line x1="{plot_x0}" y1="{plot_y0}" x2="{plot_x0}" y2="{plot_y1}" stroke="#111827" stroke-width="1.5"/>',
    ]

    for tick in x_ticks:
        x = scale(tick, x_min, x_max, plot_x0, plot_x1)
        parts.append(f'<line x1="{x:.2f}" y1="{plot_y0}" x2="{x:.2f}" y2="{plot_y1}" stroke="#e5e7eb" stroke-width="1"/>')
        parts.append(f'<text x="{x:.2f}" y="{plot_y1 + 22}" text-anchor="middle" font-size="12" fill="#4b5563">{tick:g}</text>')

    for tick in y_ticks:
        y = scale(tick, y_min, y_max, plot_y1, plot_y0)
        parts.append(f'<line x1="{plot_x0}" y1="{y:.2f}" x2="{plot_x1}" y2="{y:.2f}" stroke="#e5e7eb" stroke-width="1"/>')
        parts.append(f'<text x="{plot_x0 - 10}" y="{y + 4:.2f}" text-anchor="end" font-size="12" fill="#4b5563">{tick:g}</text>')

    parts.append(
        f'<text x="{(plot_x0 + plot_x1) / 2:.2f}" y="{y0 + PANEL_H - 12}" text-anchor="middle" font-size="13" fill="#374151">Model size (GiB)</text>'
    )
    parts.append(
        f'<text x="{x0 + 18}" y="{(plot_y0 + plot_y1) / 2:.2f}" transform="rotate(-90 {x0 + 18},{(plot_y0 + plot_y1) / 2:.2f})" text-anchor="middle" font-size="13" fill="#374151">{xml_escape(title.split(" vs ")[0])}</text>'
    )

    ordered = sorted(rows, key=lambda r: (r["size_gib"], r[metric_key]))
    label_offsets = [(-10, -12), (8, -10), (8, 16), (-10, 18), (10, 4), (-14, 6)]
    for i, row in enumerate(ordered):
        x = scale(row["size_gib"], x_min, x_max, plot_x0, plot_x1)
        y = scale(row[metric_key], y_min, y_max, plot_y1, plot_y0)
        dx, dy = label_offsets[i % len(label_offsets)]
        parts.append(
            f'<circle cx="{x:.2f}" cy="{y:.2f}" r="6.5" fill="{row["color"]}" stroke="#ffffff" stroke-width="1.5"/>'
        )
        parts.append(
            f'<text x="{x + dx:.2f}" y="{y + dy:.2f}" font-size="11" fill="#111827">{xml_escape(row["label"])}</text>'
        )
    return "\n".join(parts)


def render_legend(rows: list[dict[str, Any]], x: float, y: float) -> str:
    families = []
    seen = set()
    for row in rows:
        fam = row["family"]
        if fam in seen:
            continue
        seen.add(fam)
        families.append(fam)
    parts = [f'<text x="{x}" y="{y}" font-size="13" font-weight="700" fill="#111827">Families</text>']
    y += 18
    for i, fam in enumerate(families):
        cy = y + i * 18
        parts.append(f'<circle cx="{x + 8}" cy="{cy - 4}" r="5" fill="{PALETTE[fam]}"/>')
        parts.append(f'<text x="{x + 20}" y="{cy}" font-size="12" fill="#374151">{xml_escape(fam)}</text>')
    return "\n".join(parts)


def build_svg(rows: list[dict[str, Any]]) -> str:
    x_min = min(r["size_gib"] for r in rows)
    x_max = max(r["size_gib"] for r in rows)
    tg_min = min(r["tg_tps"] for r in rows)
    tg_max = max(r["tg_tps"] for r in rows)
    pp_min = min(r["pp_tps"] for r in rows)
    pp_max = max(r["pp_tps"] for r in rows)

    x_pad = (x_max - x_min) * 0.08 if x_max > x_min else 1
    tg_pad = (tg_max - tg_min) * 0.10 if tg_max > tg_min else 1
    pp_pad = (pp_max - pp_min) * 0.10 if pp_max > pp_min else 1

    x_min -= x_pad
    x_max += x_pad
    tg_min = max(0, tg_min - tg_pad)
    tg_max += tg_pad
    pp_min = max(0, pp_min - pp_pad)
    pp_max += pp_pad

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SVG_W}" height="{SVG_H}" viewBox="0 0 {SVG_W} {SVG_H}">',
        '<rect width="100%" height="100%" fill="#f8fafc"/>',
        '<text x="20" y="34" font-size="26" font-weight="800" fill="#111827">LLM Speed vs Size</text>',
        '<text x="20" y="56" font-size="13" fill="#4b5563">Derived from llama.cpp benchmark results in /mnt/vault/ai/models/llms/bench-results</text>',
        render_panel(rows, "Generation Speed vs Size", "tg_tps", 20, 76, x_min, x_max, tg_min, tg_max),
        render_panel(rows, "Prefill Speed vs Size", "pp_tps", 20 + PANEL_W + GAP, 76, x_min, x_max, pp_min, pp_max),
        render_legend(rows, SVG_W - 160, 30),
        "</svg>",
    ]
    return "\n".join(parts)


def main() -> int:
    args = parse_args()
    rows = build_rows(args.results_dir)
    if not rows:
        raise SystemExit("No complete benchmark rows found.")
    write_plot_data_csv(args.data_csv, rows)
    svg = build_svg(rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(svg)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
