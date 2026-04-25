#!/usr/bin/env python3
"""Render stylized context-related charts for local LLM benchmark results."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
from adjustText import adjust_text
from matplotlib.ticker import FuncFormatter


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
    parser.add_argument("--context-size-png", type=Path)
    parser.add_argument("--context-size-svg", type=Path)
    parser.add_argument("--speed-context-png", type=Path)
    parser.add_argument("--speed-context-svg", type=Path)
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


def extract_fit_series(result: dict[str, Any], metric_key: str) -> list[tuple[int, float]]:
    points: list[tuple[int, float]] = []
    probes = result.get("fit_sweep", {}).get("probes", {})
    for depth_str, probe in sorted(probes.items(), key=lambda kv: int(kv[0])):
        if not probe.get("ok"):
            continue
        metric = probe.get("metrics", {}).get(metric_key)
        if not metric:
            continue
        avg_ts = metric.get("avg_ts")
        if avg_ts is None:
            continue
        points.append((int(depth_str), float(avg_ts)))
    return points


def build_rows(results_dir: Path) -> list[dict[str, Any]]:
    rows = []
    for row in read_summary(results_dir / "summary.csv"):
        if row.get("status") != "complete":
            continue
        result = load_json(Path(row["result_file"]))
        size_gib = extract_model_size_gib(result)
        max_context = int(row["max_context_stable"]) if row["max_context_stable"] else None
        if size_gib is None or max_context is None:
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
                "max_context_stable": max_context,
                "tg_series": extract_fit_series(result, "tg"),
                "pp_series": extract_fit_series(result, "pp"),
            }
        )
    return rows


def apply_theme() -> None:
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


def format_ctx_tick(value: float, _pos: float | None = None) -> str:
    if value <= 0:
        return "0"
    rounded = int(round(value / 1024.0))
    return f"{rounded}k"


def add_points(ax: plt.Axes, rows: list[dict[str, Any]], x_key: str, y_key: str, bubble_by: str | None = None) -> None:
    for row in rows:
        size = 120
        if bubble_by:
            size = 110 + row[bubble_by] / 900
        ax.scatter(
            row[x_key],
            row[y_key],
            s=size,
            color=row["color"],
            alpha=0.9,
            edgecolor="#fffaf0",
            linewidth=1.6,
            zorder=3,
        )


def add_repel_labels(ax: plt.Axes, rows: list[dict[str, Any]], x_key: str, y_key: str) -> None:
    texts = []
    x_min, x_max = ax.get_xlim()
    y_min, y_max = ax.get_ylim()
    dx = (x_max - x_min) * 0.012
    dy = (y_max - y_min) * 0.018
    ordered = sorted(rows, key=lambda r: (r[y_key], r[x_key]))
    offsets = [
        (dx, dy),
        (dx, -dy),
        (-dx, dy),
        (-dx, -dy),
        (dx * 1.4, 0),
        (-dx * 1.4, 0),
    ]
    for i, row in enumerate(ordered):
        ox, oy = offsets[i % len(offsets)]
        texts.append(
            ax.text(
                row[x_key] + ox,
                row[y_key] + oy,
                row["label"],
                fontsize=9.0,
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
        )
    adjust_text(
        texts,
        ax=ax,
        x=[row[x_key] for row in ordered],
        y=[row[y_key] for row in ordered],
        expand=(1.08, 1.18),
        force_text=(0.35, 0.5),
        force_static=(0.2, 0.35),
        force_pull=(0.08, 0.08),
        max_move=30,
        min_arrow_len=12,
        arrowprops=dict(arrowstyle="-", color="#94a3b8", lw=0.8, alpha=0.4),
        ensure_inside_axes=True,
        avoid_self=True,
    )


def add_family_legend(fig: plt.Figure, rows: list[dict[str, Any]], anchor_y: float) -> None:
    handles = []
    for family, color in FAMILY_COLORS.items():
        if not any(row["family"] == family for row in rows):
            continue
        handles.append(
            plt.Line2D(
                [0], [0],
                marker="o",
                color="none",
                markerfacecolor=color,
                markeredgecolor="#fffaf0",
                markeredgewidth=1.2,
                markersize=10,
                label=family,
            )
        )
    fig.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, anchor_y), ncol=len(handles), frameon=False, fontsize=11)


def make_context_vs_size(rows: list[dict[str, Any]], output_png: Path, output_svg: Path) -> None:
    apply_theme()
    fig, ax = plt.subplots(figsize=(9.8, 8.2), dpi=180)
    fig.subplots_adjust(left=0.1, right=0.96, top=0.82, bottom=0.12)

    x = np.array([r["size_gib"] for r in rows])
    y = np.array([r["max_context_stable"] for r in rows])
    ax.set_title("Max Stable Context vs Model Size", fontsize=20, fontweight="bold", pad=18)
    ax.set_xlabel("Model size (GiB)", fontsize=12, labelpad=10)
    ax.set_ylabel("Max stable context", fontsize=12, labelpad=10)
    ax.grid(True, color="#e7e5e4", linewidth=1.0)
    ax.set_axisbelow(True)
    ax.set_xlim(x.min() * 0.9, x.max() * 1.06)
    ax.set_ylim(0, y.max() * 1.08)
    for spine in ax.spines.values():
        spine.set_visible(False)

    add_points(ax, rows, "size_gib", "max_context_stable", bubble_by=None)
    add_repel_labels(ax, rows, "size_gib", "max_context_stable")

    fig.suptitle("Local LLM Benchmark: Context vs Size", fontsize=24, fontweight="bold", y=0.98)
    fig.text(0.1, 0.89, "Higher is better. Dense long-context models separate clearly from large-but-shorter-context models.", fontsize=12, color="#57534e")
    add_family_legend(fig, rows, 0.93)

    output_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_png, dpi=220, bbox_inches="tight", facecolor=fig.get_facecolor())
    fig.savefig(output_svg, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close(fig)


def make_speed_vs_context(rows: list[dict[str, Any]], output_png: Path, output_svg: Path) -> None:
    apply_theme()
    fig, axes = plt.subplots(1, 2, figsize=(16.8, 8.6), dpi=180)
    fig.subplots_adjust(left=0.06, right=0.96, top=0.82, bottom=0.12, wspace=0.18)

    panels = [
        ("tg_series", "Generation Speed vs Context", "Tokens / sec"),
        ("pp_series", "Prefill Speed vs Context", "Tokens / sec"),
    ]
    contexts = np.array([depth for row in rows for depth, _ in row["tg_series"] + row["pp_series"]], dtype=float)

    for ax, (series_key, title, ylabel) in zip(axes, panels):
        values = np.array([value for row in rows for _, value in row[series_key]], dtype=float)
        ax.set_title(title, fontsize=17, fontweight="bold", pad=16)
        ax.set_xlabel("Tested context size", fontsize=12, labelpad=10)
        ax.set_ylabel(ylabel, fontsize=12, labelpad=10)
        ax.grid(True, color="#e7e5e4", linewidth=1.0)
        ax.set_axisbelow(True)
        ax.set_xscale("log", base=2)
        ax.set_xlim(max(2048, contexts.min() * 0.9), contexts.max() * 1.08)
        ax.set_ylim(0, values.max() * 1.12)
        ax.xaxis.set_major_formatter(FuncFormatter(format_ctx_tick))
        for spine in ax.spines.values():
            spine.set_visible(False)

        final_rows = []
        for row in rows:
            series = row[series_key]
            if not series:
                continue
            xs = [x for x, _ in series]
            ys = [y for _, y in series]
            ax.plot(xs, ys, color=row["color"], linewidth=2.0, alpha=0.82, zorder=2)
            ax.scatter(
                xs,
                ys,
                s=34 + row["size_gib"] * 2.6,
                color=row["color"],
                alpha=0.92,
                edgecolor="#fffaf0",
                linewidth=1.0,
                zorder=3,
            )
            final_rows.append(
                {
                    "label": row["label"],
                    "color": row["color"],
                    "x": xs[-1],
                    "y": ys[-1],
                }
            )

        add_repel_labels_for_points(ax, final_rows)

    fig.suptitle("Local LLM Benchmark: Speed vs Context", fontsize=24, fontweight="bold", y=0.98)
    fig.text(0.07, 0.89, "Each line uses the actual fit-sweep probe points. Left: generation throughput. Right: prefill throughput.", fontsize=12, color="#57534e")
    add_family_legend(fig, rows, 0.93)

    output_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_png, dpi=220, bbox_inches="tight", facecolor=fig.get_facecolor())
    fig.savefig(output_svg, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close(fig)


def add_repel_labels_for_points(ax: plt.Axes, points: list[dict[str, Any]]) -> None:
    texts = []
    x_min, x_max = ax.get_xlim()
    y_min, y_max = ax.get_ylim()
    dx = (x_max - x_min) * 0.01
    dy = (y_max - y_min) * 0.018
    ordered = sorted(points, key=lambda r: (r["y"], r["x"]))
    offsets = [
        (dx, dy),
        (dx, -dy),
        (-dx, dy),
        (-dx, -dy),
        (dx * 1.5, 0),
        (-dx * 1.5, 0),
    ]
    for i, point in enumerate(ordered):
        ox, oy = offsets[i % len(offsets)]
        texts.append(
            ax.text(
                point["x"] + ox,
                point["y"] + oy,
                point["label"],
                fontsize=9.0,
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
        )
    adjust_text(
        texts,
        ax=ax,
        x=[p["x"] for p in ordered],
        y=[p["y"] for p in ordered],
        expand=(1.05, 1.14),
        force_text=(0.25, 0.45),
        force_static=(0.16, 0.3),
        force_pull=(0.05, 0.05),
        max_move=28,
        min_arrow_len=10,
        arrowprops=dict(arrowstyle="-", color="#94a3b8", lw=0.8, alpha=0.35),
        ensure_inside_axes=True,
        avoid_self=True,
    )


def main() -> int:
    args = parse_args()
    if args.context_size_png is None:
        args.context_size_png = args.results_dir / "context_vs_size_stylized.png"
    if args.context_size_svg is None:
        args.context_size_svg = args.results_dir / "context_vs_size_stylized.svg"
    if args.speed_context_png is None:
        args.speed_context_png = args.results_dir / "speed_vs_context_stylized.png"
    if args.speed_context_svg is None:
        args.speed_context_svg = args.results_dir / "speed_vs_context_stylized.svg"
    rows = build_rows(args.results_dir)
    if not rows:
        raise SystemExit("No complete benchmark rows found.")
    make_context_vs_size(rows, args.context_size_png, args.context_size_svg)
    make_speed_vs_context(rows, args.speed_context_png, args.speed_context_svg)
    print(args.context_size_png)
    print(args.context_size_svg)
    print(args.speed_context_png)
    print(args.speed_context_svg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
