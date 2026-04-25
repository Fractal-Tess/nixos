#!/usr/bin/env python3
"""Render a stylized speed-vs-size chart for local LLM benchmark results."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
from adjustText import adjust_text


DEFAULT_RESULTS_DIR = Path("/mnt/vault/ai/models/llms/bench-results")

FAMILY_COLORS = {
    "Qwen": "#0f766e",
    "Gemma": "#c2410c",
    "Mistral": "#1d4ed8",
    "Hermes": "#7c3aed",
    "DeepSeek": "#dc2626",
    "Phi": "#9333ea",
    "Other": "#475569",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_DIR)
    parser.add_argument("--output-png", type=Path)
    parser.add_argument("--output-svg", type=Path)
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
    label = model_id
    replacements = [
        ("Qwen3.6-", "Q3.6 "),
        ("Qwen3.5-", "Q3.5 "),
        ("Qwen2.5-", "Q2.5 "),
        ("gemma-4-", "Gem4 "),
        ("Hermes-3-Llama-3.1-", "Hermes "),
        ("DeepSeek-R1-Distill-Qwen-", "DS-R1 "),
        ("Mistral-Small-", "Mistral "),
        ("-A3B-APEX-I-Quality", " 35B IQ"),
        ("-UD-Q4_K_XL", " XL"),
        ("-Q4_K_M", " Q4KM"),
        ("-Q6_K_XL", " Q6XL"),
        ("-Q6_K", " Q6K"),
        ("-A4B-it", " A4B"),
        ("-Instruct", " Inst"),
        ("-ultra-uncensored-heretic-v2", " Heretic"),
    ]
    for src, dst in replacements:
        label = label.replace(src, dst)
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
    for row in read_summary(results_dir / "summary.csv"):
        if row.get("status") != "complete":
            continue
        result = load_json(Path(row["result_file"]))
        size_gib = extract_model_size_gib(result)
        if size_gib is None:
            continue
        model_id = row["model_id"]
        family = family_for(model_id)
        rows.append(
            {
                "model_id": model_id,
                "label": short_label(model_id),
                "family": family,
                "color": FAMILY_COLORS[family],
                "size_gib": size_gib,
                "tg_tps": float(row["tg_avg_tps_last"]),
                "pp_tps": float(row["pp_avg_tps_last"]),
                "max_context_stable": int(row["max_context_stable"]) if row["max_context_stable"] else None,
            }
        )
    return rows


def make_plot(rows: list[dict[str, Any]], output_png: Path, output_svg: Path) -> None:
    plt.rcParams.update(
        {
            "font.size": 11,
            "axes.facecolor": "#ffffff",
            "figure.facecolor": "#f6f4ee",
            "axes.edgecolor": "#d6d3d1",
            "axes.labelcolor": "#1c1917",
            "xtick.color": "#44403c",
            "ytick.color": "#44403c",
            "text.color": "#1c1917",
        }
    )

    fig, axes = plt.subplots(1, 2, figsize=(16.8, 8.6), dpi=180)
    fig.subplots_adjust(left=0.06, right=0.96, top=0.82, bottom=0.12, wspace=0.18)

    metrics = [
        ("tg_tps", "Generation Speed", "Tokens / sec"),
        ("pp_tps", "Prefill Speed", "Tokens / sec"),
    ]

    sizes = np.array([row["size_gib"] for row in rows])
    size_min = sizes.min()
    size_max = sizes.max()

    for ax, (metric_key, title, ylabel) in zip(axes, metrics):
        values = np.array([row[metric_key] for row in rows])
        ax.set_title(title, fontsize=17, fontweight="bold", pad=16)
        ax.set_xlabel("Model size (GiB)", fontsize=12, labelpad=10)
        ax.set_ylabel(ylabel, fontsize=12, labelpad=10)
        ax.grid(True, color="#e7e5e4", linewidth=1.0)
        ax.set_axisbelow(True)
        ax.set_xlim(size_min * 0.9, size_max * 1.06)
        ax.set_ylim(0, values.max() * 1.12)

        for spine in ax.spines.values():
            spine.set_visible(False)

        for row in rows:
            x = row["size_gib"]
            y = row[metric_key]
            bubble = 110 + (row["max_context_stable"] or 0) / 900
            ax.scatter(
                x,
                y,
                s=bubble,
                color=row["color"],
                alpha=0.9,
                edgecolor="#fffaf0",
                linewidth=1.6,
                zorder=3,
            )

        add_repel_labels(ax, rows, metric_key)

    legend_handles = []
    for family, color in FAMILY_COLORS.items():
        if not any(row["family"] == family for row in rows):
            continue
        legend_handles.append(
            plt.Line2D(
                [0],
                [0],
                marker="o",
                color="none",
                markerfacecolor=color,
                markeredgecolor="#fffaf0",
                markeredgewidth=1.2,
                markersize=10,
                label=family,
            )
        )

    fig.legend(
        handles=legend_handles,
        loc="upper center",
        bbox_to_anchor=(0.5, 0.93),
        ncol=len(legend_handles),
        frameon=False,
        fontsize=11,
    )

    fig.suptitle("Local LLM Benchmark: Speed vs Size", fontsize=24, fontweight="bold", y=0.98)
    fig.text(
        0.07,
        0.89,
        "Bubble size encodes max stable context. Left: generation throughput. Right: prefill throughput.",
        fontsize=12,
        color="#57534e",
    )

    output_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_png, dpi=220, bbox_inches="tight", facecolor=fig.get_facecolor())
    fig.savefig(output_svg, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close(fig)


def add_repel_labels(ax: plt.Axes, rows: list[dict[str, Any]], metric_key: str) -> None:
    texts = []
    x_min, x_max = ax.get_xlim()
    y_min, y_max = ax.get_ylim()
    dx = (x_max - x_min) * 0.012
    dy = (y_max - y_min) * 0.018

    ordered = sorted(rows, key=lambda r: (r[metric_key], r["size_gib"]))
    offsets = [
        (dx, dy),
        (dx, -dy),
        (-dx, dy),
        (-dx, -dy),
        (dx * 1.4, 0),
        (-dx * 1.4, 0),
    ]

    for i, row in enumerate(ordered):
        off_x, off_y = offsets[i % len(offsets)]
        text = ax.text(
            row["size_gib"] + off_x,
            row[metric_key] + off_y,
            row["label"],
            fontsize=9.2,
            color="#1f2937",
            va="center",
            ha="left",
            bbox={
                "boxstyle": "round,pad=0.22,rounding_size=0.18",
                "fc": "#fffdf7",
                "ec": "#e7e5e4",
                "lw": 0.8,
                "alpha": 0.97,
            },
            zorder=4,
        )
        texts.append(text)

    adjust_text(
        texts,
        ax=ax,
        x=[row["size_gib"] for row in ordered],
        y=[row[metric_key] for row in ordered],
        expand=(1.08, 1.18),
        force_text=(0.35, 0.5),
        force_static=(0.2, 0.35),
        force_pull=(0.08, 0.08),
        max_move=30,
        min_arrow_len=12,
        arrowprops=dict(
            arrowstyle="-",
            color="#94a3b8",
            lw=0.8,
            alpha=0.45,
        ),
        ensure_inside_axes=True,
        avoid_self=True,
    )


def main() -> int:
    args = parse_args()
    if args.output_png is None:
        args.output_png = args.results_dir / "speed_vs_size_stylized.png"
    if args.output_svg is None:
        args.output_svg = args.results_dir / "speed_vs_size_stylized.svg"
    rows = build_rows(args.results_dir)
    if not rows:
        raise SystemExit("No complete benchmark rows found.")
    make_plot(rows, args.output_png, args.output_svg)
    print(args.output_png)
    print(args.output_svg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
