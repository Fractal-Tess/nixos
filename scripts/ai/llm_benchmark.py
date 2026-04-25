#!/usr/bin/env python3
"""Resumable llama.cpp benchmark harness for local GGUF models.

v1 scope:
- discover GGUF models from a directory
- skip models with completed result files
- find max stable context with llama-bench
- benchmark parallel decode scaling with llama-batched-bench
- persist JSON results after every probe so runs can resume cleanly

The harness intentionally does not set cache-type overrides.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCRIPT_VERSION = 1
DEFAULT_MODEL_DIR = Path("/mnt/vault/ai/models/llms")
DEFAULT_RESULTS_DIR = DEFAULT_MODEL_DIR / "bench-results"
DEFAULT_LLAMA_BENCH = Path(
    "/nix/store/76fl2pkvrlyswxgyv6sabkhcl3i51ik3-llama-cpp-8797/bin/llama-bench"
)
DEFAULT_LLAMA_BATCHED_BENCH = Path(
    "/nix/store/76fl2pkvrlyswxgyv6sabkhcl3i51ik3-llama-cpp-8797/bin/llama-batched-bench"
)
DEFAULT_CHART_PYTHON = DEFAULT_MODEL_DIR / ".venvs" / "llm-charts" / "bin" / "python"
DEFAULT_SPEED_SIZE_CHART = Path("/home/fractal-tess/nixos/scripts/ai/llm_speed_size_chart_stylized.py")
DEFAULT_CONTEXT_CHARTS = Path("/home/fractal-tess/nixos/scripts/ai/llm_context_charts_stylized.py")

@dataclass
class CommandResult:
    ok: bool
    exit_code: int
    stdout: str
    stderr: str
    duration_s: float
    failure_type: str | None = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-dir", type=Path, default=DEFAULT_MODEL_DIR)
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_DIR)
    parser.add_argument("--model", action="append", help="Specific model path(s) to run")
    parser.add_argument("--match", help="Only run models whose filename contains this text")
    parser.add_argument("--max-models", type=int, default=0, help="Limit model count (0 = no limit)")
    parser.add_argument("--force", action="store_true", help="Re-run even if result file is complete")
    parser.add_argument("--bench-bin", type=Path, default=DEFAULT_LLAMA_BENCH)
    parser.add_argument("--batched-bin", type=Path, default=DEFAULT_LLAMA_BATCHED_BENCH)
    parser.add_argument("--sudo", action="store_true", help="Prefix llama.cpp commands with sudo -E")
    parser.add_argument("--device", default="CUDA0")
    parser.add_argument("--n-gpu-layers", type=int, default=99)
    parser.add_argument("--split-mode", default="none", choices=["none", "layer", "row", "tensor"])
    parser.add_argument("--flash-attn", type=int, default=1, choices=[0, 1])
    parser.add_argument("--start-depth", type=int, default=4096)
    parser.add_argument("--max-depth", type=int, default=131072)
    parser.add_argument("--refine-step", type=int, default=2048)
    parser.add_argument("--fit-prompt-tokens", type=int, default=512)
    parser.add_argument("--fit-gen-tokens", type=int, default=32)
    parser.add_argument("--parallel-values", default="1,2,4,8")
    parser.add_argument("--parallel-prompt-tokens", type=int, default=512)
    parser.add_argument("--parallel-gen-tokens", type=int, default=32)
    parser.add_argument("--timeout-fit", type=int, default=900)
    parser.add_argument("--timeout-parallel", type=int, default=900)
    parser.add_argument(
        "--cleanup-ollama",
        action="store_true",
        help="Stop all loaded Ollama models before benchmarking each model",
    )
    parser.add_argument(
        "--stop-container",
        action="append",
        default=[],
        help="Docker container(s) to stop before benchmarking",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Regenerate summary CSV from result files without running benchmarks",
    )
    parser.add_argument(
        "--skip-charts",
        action="store_true",
        help="Skip automatic chart regeneration after summaries are updated",
    )
    return parser.parse_args()


def ensure_binary(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"Missing binary: {path}")


def run_command(cmd: list[str], timeout: int) -> CommandResult:
    started = time.time()
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            errors="replace",
            timeout=timeout,
            check=False,
        )
        duration = time.time() - started
        ok = proc.returncode == 0
        failure_type = None
        if not ok:
            failure_type = classify_failure(proc.returncode, proc.stdout, proc.stderr)
        return CommandResult(
            ok=ok,
            exit_code=proc.returncode,
            stdout=proc.stdout,
            stderr=proc.stderr,
            duration_s=duration,
            failure_type=failure_type,
        )
    except subprocess.TimeoutExpired as exc:
        duration = time.time() - started
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        return CommandResult(
            ok=False,
            exit_code=124,
            stdout=stdout,
            stderr=stderr,
            duration_s=duration,
            failure_type="timeout",
        )


def classify_failure(exit_code: int, stdout: str, stderr: str) -> str:
    text = f"{stdout}\n{stderr}".lower()
    if "failed to create context" in text:
        return "create_context_failed"
    if "cuda error" in text:
        return "cuda_error"
    if "out of memory" in text or "oom" in text:
        return "oom_like"
    if "aborted" in text or exit_code == 134:
        return "aborted"
    return "nonzero_exit"


def command_prefix(use_sudo: bool) -> list[str]:
    return ["sudo", "-E"] if use_sudo else []


def model_id_for(path: Path) -> str:
    return path.stem


def result_path_for(results_dir: Path, model_path: Path) -> Path:
    return results_dir / f"{model_id_for(model_path)}.json"


def logs_dir_for(results_dir: Path, model_path: Path) -> Path:
    return results_dir / "logs" / model_id_for(model_path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def write_probe_logs(base_dir: Path, stem: str, stdout: str, stderr: str) -> dict[str, str]:
    base_dir.mkdir(parents=True, exist_ok=True)
    stdout_path = base_dir / f"{stem}.stdout.log"
    stderr_path = base_dir / f"{stem}.stderr.log"
    stdout_path.write_text(stdout)
    stderr_path.write_text(stderr)
    return {
        "stdout_log": str(stdout_path),
        "stderr_log": str(stderr_path),
    }


def discover_models(args: argparse.Namespace) -> list[Path]:
    if args.model:
        models = [Path(p).expanduser().resolve() for p in args.model]
    else:
        models = sorted(args.model_dir.glob("*.gguf"))
    if args.match:
        models = [p for p in models if args.match.lower() in p.name.lower()]
    if args.max_models > 0:
        models = models[: args.max_models]
    return models


def gpu_snapshot() -> dict[str, Any]:
    query = [
        "nvidia-smi",
        "--query-gpu=memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu,power.draw",
        "--format=csv,noheader,nounits",
    ]
    res = run_command(query, timeout=10)
    if not res.ok or not res.stdout.strip():
        return {}
    first = res.stdout.strip().splitlines()[0]
    parts = [part.strip() for part in first.split(",")]
    if len(parts) != 6:
        return {"raw": first}
    return {
        "memory_total_mib": to_int(parts[0]),
        "memory_used_mib": to_int(parts[1]),
        "memory_free_mib": to_int(parts[2]),
        "gpu_util_percent": to_int(parts[3]),
        "temperature_c": to_int(parts[4]),
        "power_draw_w": to_float(parts[5]),
    }


def to_int(value: str) -> int | None:
    try:
        return int(value)
    except ValueError:
        return None


def to_float(value: str) -> float | None:
    try:
        return float(value)
    except ValueError:
        return None


def summarize_fit_metrics(objs: list[dict[str, Any]]) -> dict[str, Any]:
    summary: dict[str, Any] = {"raw": objs}
    for obj in objs:
        kind = fit_kind_for(obj)
        if kind is None:
            continue
        summary[kind] = obj
    return summary


def fit_kind_for(obj: dict[str, Any]) -> str | None:
    if obj.get("n_prompt", 0) and not obj.get("n_gen", 0):
        return "pp"
    if obj.get("n_gen", 0) and not obj.get("n_prompt", 0):
        return "tg"
    return None


def extract_perf_stats(stderr: str) -> dict[str, Any]:
    stats: dict[str, Any] = {}
    patterns = {
        "cpu_mapped_model_buffer_mib": r"CPU_Mapped model buffer size =\s+([0-9.]+) MiB",
        "cuda_model_buffer_mib": r"CUDA0 model buffer size =\s+([0-9.]+) MiB",
        "cuda_kv_buffer_mib": r"CUDA0 KV buffer size =\s+([0-9.]+) MiB",
        "cuda_host_output_buffer_mib": r"CUDA_Host\s+output buffer size =\s+([0-9.]+) MiB",
        "cuda_compute_buffer_mib": r"CUDA0 compute buffer size =\s+([0-9.]+) MiB",
        "cuda_host_compute_buffer_mib": r"CUDA_Host compute buffer size =\s+([0-9.]+) MiB",
        "graph_nodes": r"graph nodes\s+=\s+([0-9]+)",
        "graph_splits": r"graph splits\s+=\s+([0-9]+)",
        "load_time_ms": r"llama_perf_context_print:\s+load time =\s+([0-9.]+) ms",
        "prompt_eval_ms": r"llama_perf_context_print:\s+prompt eval time =\s+([0-9.]+) ms",
        "prompt_eval_tps": r"llama_perf_context_print:\s+prompt eval time =.*?,\s+([0-9.]+) tokens per second\)",
        "eval_time_ms": r"llama_perf_context_print:\s+eval time =\s+([0-9.]+) ms",
        "eval_tps": r"llama_perf_context_print:\s+eval time =.*?,\s+([0-9.]+) tokens per second\)",
        "total_time_ms": r"llama_perf_context_print:\s+total time =\s+([0-9.]+) ms",
        "graphs_reused": r"graphs reused =\s+([0-9]+)",
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, stderr)
        if not match:
            continue
        value = match.group(1)
        if key.endswith("_mib") or key.endswith("_ms") or key.endswith("_tps"):
            stats[key] = to_float(value)
        else:
            stats[key] = to_int(value)
    return stats


def run_fit_probe(args: argparse.Namespace, model: Path, depth: int, logs_dir: Path) -> dict[str, Any]:
    gpu_before = gpu_snapshot()
    cmd = command_prefix(args.sudo) + [
        str(args.bench_bin),
        "--model",
        str(model),
        "--n-gpu-layers",
        str(args.n_gpu_layers),
        "--device",
        args.device,
        "--split-mode",
        args.split_mode,
        "--flash-attn",
        str(args.flash_attn),
        "--n-prompt",
        str(args.fit_prompt_tokens),
        "--n-gen",
        str(args.fit_gen_tokens),
        "--n-depth",
        str(depth),
        "--output",
        "jsonl",
    ]
    res = run_command(cmd, args.timeout_fit)
    gpu_after = gpu_snapshot()
    metrics = extract_jsonl_objects(res.stdout)
    log_paths = write_probe_logs(logs_dir, f"fit-depth-{depth}", res.stdout, res.stderr)
    probe: dict[str, Any] = {
        "command": cmd,
        "depth": depth,
        "ok": res.ok,
        "exit_code": res.exit_code,
        "duration_s": round(res.duration_s, 3),
        "failure_type": res.failure_type,
        "gpu_before": gpu_before,
        "gpu_after": gpu_after,
        **log_paths,
        "stdout_tail": tail(res.stdout, 20),
        "stderr_tail": tail(res.stderr, 40),
        "metrics": summarize_fit_metrics(metrics),
        "perf_stats": extract_perf_stats(res.stderr),
    }
    return probe


def midpoint_aligned(lo: int, hi: int, step: int) -> int:
    mid = (lo + hi) // 2
    aligned = (mid // step) * step
    if aligned <= lo:
        aligned = lo + step
    if aligned >= hi:
        aligned = hi - step
    return aligned


def fit_sweep(args: argparse.Namespace, model: Path, result: dict[str, Any], result_path: Path) -> tuple[int | None, list[int]]:
    fit_state = result.setdefault("fit_sweep", {})
    probes = fit_state.setdefault("probes", {})
    coarse_successes: list[int] = []
    depth = args.start_depth
    last_success: int | None = None
    first_failure: int | None = None

    while depth <= args.max_depth:
        probe = get_or_run_fit_probe(args, model, result, result_path, depth)
        if probe["ok"]:
            coarse_successes.append(depth)
            last_success = depth
            next_depth = depth * 2
            if next_depth == depth:
                break
            depth = next_depth
            continue
        first_failure = depth
        break

    if last_success is None:
        fit_state["max_context_stable"] = None
        fit_state["first_failure_context"] = first_failure
        write_json(result_path, result)
        return None, []

    if first_failure is None:
        fit_state["max_context_stable"] = last_success
        fit_state["first_failure_context"] = None
        fit_state["max_context_reached_search_limit"] = last_success >= args.max_depth
        write_json(result_path, result)
        return last_success, coarse_successes

    lo = last_success
    hi = first_failure
    while (hi - lo) > args.refine_step:
        mid = midpoint_aligned(lo, hi, args.refine_step)
        if mid <= lo or mid >= hi:
            break
        probe = get_or_run_fit_probe(args, model, result, result_path, mid)
        if probe["ok"]:
            lo = mid
        else:
            hi = mid

    fit_state["max_context_stable"] = lo
    fit_state["first_failure_context"] = hi
    fit_state["coarse_successes"] = coarse_successes
    write_json(result_path, result)
    return lo, coarse_successes


def get_or_run_fit_probe(
    args: argparse.Namespace,
    model: Path,
    result: dict[str, Any],
    result_path: Path,
    depth: int,
) -> dict[str, Any]:
    probes = result.setdefault("fit_sweep", {}).setdefault("probes", {})
    key = str(depth)
    if key in probes:
        return probes[key]
    probe = run_fit_probe(args, model, depth, logs_dir_for(args.results_dir, model))
    probes[key] = probe
    write_json(result_path, result)
    return probe


def run_parallel_probe(
    args: argparse.Namespace,
    model: Path,
    context: int,
    parallel: int,
    logs_dir: Path,
) -> dict[str, Any]:
    gpu_before = gpu_snapshot()
    cmd = command_prefix(args.sudo) + [
        str(args.batched_bin),
        "--model",
        str(model),
        "--ctx-size",
        str(context),
        "--n-gpu-layers",
        str(args.n_gpu_layers),
        "--device",
        args.device,
        "--split-mode",
        args.split_mode,
        "--flash-attn",
        str(args.flash_attn),
        "-npp",
        str(args.parallel_prompt_tokens),
        "-ntg",
        str(args.parallel_gen_tokens),
        "-npl",
        str(parallel),
        "--output-format",
        "jsonl",
    ]
    res = run_command(cmd, args.timeout_parallel)
    gpu_after = gpu_snapshot()
    metrics = extract_jsonl_objects(res.stdout)
    log_paths = write_probe_logs(logs_dir, f"parallel-ctx-{context}-p-{parallel}", res.stdout, res.stderr)
    return {
        "command": cmd,
        "context": context,
        "parallel": parallel,
        "ok": res.ok and len(metrics) > 0,
        "exit_code": res.exit_code,
        "duration_s": round(res.duration_s, 3),
        "failure_type": None if (res.ok and metrics) else res.failure_type or "missing_jsonl",
        "gpu_before": gpu_before,
        "gpu_after": gpu_after,
        **log_paths,
        "stdout_tail": tail(res.stdout, 20),
        "stderr_tail": tail(res.stderr, 40),
        "metrics": metrics[-1] if metrics else {},
        "perf_stats": extract_perf_stats(res.stderr),
    }


def extract_jsonl_objects(text: str) -> list[dict[str, Any]]:
    objs: list[dict[str, Any]] = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("{") or not line.endswith("}"):
            continue
        try:
            objs.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return objs


def planned_parallel_contexts(max_stable: int | None, coarse_successes: list[int]) -> list[int]:
    if max_stable is None:
        return []
    contexts = []
    for depth in coarse_successes:
        if depth <= max_stable:
            contexts.append(depth)
    if max_stable not in contexts:
        contexts.append(max_stable)
    return sorted(set(contexts))


def run_parallel_matrix(
    args: argparse.Namespace,
    model: Path,
    result: dict[str, Any],
    result_path: Path,
    max_stable: int | None,
    coarse_successes: list[int],
) -> None:
    contexts = planned_parallel_contexts(max_stable, coarse_successes)
    values = [int(v) for v in args.parallel_values.split(",") if v.strip()]
    parallel_state = result.setdefault("parallel_sweep", {})
    probes = parallel_state.setdefault("probes", {})
    model_logs_dir = logs_dir_for(args.results_dir, model)

    for context in contexts:
        for parallel in values:
            key = f"{context}:{parallel}"
            if key in probes:
                continue
            probe = run_parallel_probe(args, model, context, parallel, model_logs_dir)
            probes[key] = probe
            write_json(result_path, result)

    parallel_state["contexts"] = contexts
    parallel_state["parallel_values"] = values
    write_json(result_path, result)


def cleanup_runtime(args: argparse.Namespace) -> None:
    if args.cleanup_ollama:
        stop_all_ollama_models()
    for container in args.stop_container:
        run_command(["docker", "stop", container], timeout=120)


def stop_all_ollama_models() -> None:
    res = run_command(["ollama", "ps"], timeout=30)
    if not res.ok:
        return
    lines = [line.rstrip() for line in res.stdout.splitlines() if line.strip()]
    for line in lines[1:]:
        name = line.split()[0]
        if not name:
            continue
        run_command(["ollama", "stop", name], timeout=120)


def init_result(model: Path) -> dict[str, Any]:
    return {
        "script_version": SCRIPT_VERSION,
        "model_id": model_id_for(model),
        "model_path": str(model),
        "status": "pending",
        "fit_sweep": {"probes": {}},
        "parallel_sweep": {"probes": {}},
    }


def summarize_results(results_dir: Path) -> Path:
    summary_path = results_dir / "summary.csv"
    fit_detail_path = results_dir / "fit_probes.csv"
    parallel_detail_path = results_dir / "parallel_probes.csv"
    rows: list[dict[str, Any]] = []
    fit_rows: list[dict[str, Any]] = []
    parallel_rows: list[dict[str, Any]] = []
    for path in sorted(results_dir.glob("*.json")):
        data = read_json(path)
        fit = data.get("fit_sweep", {})
        parallel = data.get("parallel_sweep", {}).get("probes", {})
        probes = fit.get("probes", {})
        pp_best = None
        tg_best = None
        for probe in probes.values():
            metrics = probe.get("metrics", {})
            if metrics.get("pp"):
                pp_best = metrics["pp"]
            if metrics.get("tg"):
                tg_best = metrics["tg"]
        rows.append(
            {
                "model_id": data.get("model_id", path.stem),
                "status": data.get("status", "unknown"),
                "max_context_stable": fit.get("max_context_stable"),
                "first_failure_context": fit.get("first_failure_context"),
                "pp_avg_tps_last": pp_best.get("avg_ts") if pp_best else None,
                "pp_stddev_tps_last": pp_best.get("stddev_ts") if pp_best else None,
                "tg_avg_tps_last": tg_best.get("avg_ts") if tg_best else None,
                "tg_stddev_tps_last": tg_best.get("stddev_ts") if tg_best else None,
                "parallel_probe_count": len(parallel),
                "result_file": str(path),
            }
        )
        for depth, probe in sorted(probes.items(), key=lambda item: int(item[0])):
            metrics = probe.get("metrics", {})
            for kind in ("pp", "tg"):
                metric = metrics.get(kind)
                if not metric:
                    continue
                fit_rows.append(
                    {
                        "model_id": data.get("model_id", path.stem),
                        "depth": depth,
                        "kind": kind,
                        "ok": probe.get("ok"),
                        "exit_code": probe.get("exit_code"),
                        "failure_type": probe.get("failure_type"),
                        "avg_tps": metric.get("avg_ts"),
                        "stddev_tps": metric.get("stddev_ts"),
                        "avg_ns": metric.get("avg_ns"),
                        "stddev_ns": metric.get("stddev_ns"),
                        "n_prompt": metric.get("n_prompt"),
                        "n_gen": metric.get("n_gen"),
                        "n_batch": metric.get("n_batch"),
                        "n_ubatch": metric.get("n_ubatch"),
                        "n_threads": metric.get("n_threads"),
                        "n_gpu_layers": metric.get("n_gpu_layers"),
                        "flash_attn": metric.get("flash_attn"),
                        "backends": metric.get("backends"),
                        "devices": metric.get("devices"),
                        "model_type": metric.get("model_type"),
                        "model_size": metric.get("model_size"),
                        "model_n_params": metric.get("model_n_params"),
                        "gpu_mem_used_before_mib": probe.get("gpu_before", {}).get("memory_used_mib"),
                        "gpu_mem_used_after_mib": probe.get("gpu_after", {}).get("memory_used_mib"),
                        "duration_s": probe.get("duration_s"),
                    }
                )
        for key, probe in sorted(parallel.items()):
            metric = probe.get("metrics", {})
            perf = probe.get("perf_stats", {})
            parallel_rows.append(
                {
                    "model_id": data.get("model_id", path.stem),
                    "context": probe.get("context"),
                    "parallel": probe.get("parallel"),
                    "ok": probe.get("ok"),
                    "exit_code": probe.get("exit_code"),
                    "failure_type": probe.get("failure_type"),
                    "speed_total_tps": metric.get("speed"),
                    "speed_pp_tps": metric.get("speed_pp"),
                    "speed_tg_tps": metric.get("speed_tg"),
                    "t_total_s": metric.get("t"),
                    "t_pp_s": metric.get("t_pp"),
                    "t_tg_s": metric.get("t_tg"),
                    "n_kv": metric.get("n_kv"),
                    "n_kv_max": metric.get("n_kv_max"),
                    "n_batch": metric.get("n_batch"),
                    "n_ubatch": metric.get("n_ubatch"),
                    "n_threads": metric.get("n_threads"),
                    "n_threads_batch": metric.get("n_threads_batch"),
                    "n_gpu_layers": metric.get("n_gpu_layers"),
                    "flash_attn": metric.get("flash_attn"),
                    "cpu_mapped_model_buffer_mib": perf.get("cpu_mapped_model_buffer_mib"),
                    "cuda_model_buffer_mib": perf.get("cuda_model_buffer_mib"),
                    "cuda_kv_buffer_mib": perf.get("cuda_kv_buffer_mib"),
                    "cuda_host_output_buffer_mib": perf.get("cuda_host_output_buffer_mib"),
                    "cuda_compute_buffer_mib": perf.get("cuda_compute_buffer_mib"),
                    "cuda_host_compute_buffer_mib": perf.get("cuda_host_compute_buffer_mib"),
                    "graph_nodes": perf.get("graph_nodes"),
                    "graph_splits": perf.get("graph_splits"),
                    "load_time_ms": perf.get("load_time_ms"),
                    "prompt_eval_ms": perf.get("prompt_eval_ms"),
                    "prompt_eval_tps": perf.get("prompt_eval_tps"),
                    "eval_time_ms": perf.get("eval_time_ms"),
                    "eval_tps": perf.get("eval_tps"),
                    "total_time_ms": perf.get("total_time_ms"),
                    "graphs_reused": perf.get("graphs_reused"),
                    "gpu_mem_used_before_mib": probe.get("gpu_before", {}).get("memory_used_mib"),
                    "gpu_mem_used_after_mib": probe.get("gpu_after", {}).get("memory_used_mib"),
                    "duration_s": probe.get("duration_s"),
                    "probe_key": key,
                }
            )
    results_dir.mkdir(parents=True, exist_ok=True)
    with summary_path.open("w", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "model_id",
                "status",
                "max_context_stable",
                "first_failure_context",
                "pp_avg_tps_last",
                "pp_stddev_tps_last",
                "tg_avg_tps_last",
                "tg_stddev_tps_last",
                "parallel_probe_count",
                "result_file",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)
    with fit_detail_path.open("w", newline="") as handle:
        fieldnames = [
            "model_id",
            "depth",
            "kind",
            "ok",
            "exit_code",
            "failure_type",
            "avg_tps",
            "stddev_tps",
            "avg_ns",
            "stddev_ns",
            "n_prompt",
            "n_gen",
            "n_batch",
            "n_ubatch",
            "n_threads",
            "n_gpu_layers",
            "flash_attn",
            "backends",
            "devices",
            "model_type",
            "model_size",
            "model_n_params",
            "gpu_mem_used_before_mib",
            "gpu_mem_used_after_mib",
            "duration_s",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(fit_rows)
    with parallel_detail_path.open("w", newline="") as handle:
        fieldnames = [
            "model_id",
            "context",
            "parallel",
            "ok",
            "exit_code",
            "failure_type",
            "speed_total_tps",
            "speed_pp_tps",
            "speed_tg_tps",
            "t_total_s",
            "t_pp_s",
            "t_tg_s",
            "n_kv",
            "n_kv_max",
            "n_batch",
            "n_ubatch",
            "n_threads",
            "n_threads_batch",
            "n_gpu_layers",
            "flash_attn",
            "cpu_mapped_model_buffer_mib",
            "cuda_model_buffer_mib",
            "cuda_kv_buffer_mib",
            "cuda_host_output_buffer_mib",
            "cuda_compute_buffer_mib",
            "cuda_host_compute_buffer_mib",
            "graph_nodes",
            "graph_splits",
            "load_time_ms",
            "prompt_eval_ms",
            "prompt_eval_tps",
            "eval_time_ms",
            "eval_tps",
            "total_time_ms",
            "graphs_reused",
            "gpu_mem_used_before_mib",
            "gpu_mem_used_after_mib",
            "duration_s",
            "probe_key",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(parallel_rows)
    return summary_path


def regenerate_charts(args: argparse.Namespace) -> None:
    if args.skip_charts:
        return
    python_bin = DEFAULT_CHART_PYTHON
    if not python_bin.is_file():
        print(f"charts skipped: missing venv python at {python_bin}", file=sys.stderr)
        return

    chart_scripts = [
        DEFAULT_SPEED_SIZE_CHART,
        DEFAULT_CONTEXT_CHARTS,
    ]
    for script in chart_scripts:
        if not script.is_file():
            print(f"charts skipped: missing script {script}", file=sys.stderr)
            continue
        res = run_command([str(python_bin), str(script), "--results-dir", str(args.results_dir)], timeout=1800)
        if not res.ok:
            print(f"chart generation failed for {script.name}", file=sys.stderr)
            if res.stderr.strip():
                print(tail(res.stderr, 20), file=sys.stderr)
            continue
        if res.stdout.strip():
            print(res.stdout.strip())


def tail(text: str, max_lines: int) -> list[str]:
    return text.splitlines()[-max_lines:]


def run_model(args: argparse.Namespace, model: Path) -> None:
    result_path = result_path_for(args.results_dir, model)
    if args.force or not result_path.exists():
        result = init_result(model)
    else:
        result = read_json(result_path)
    if (
        not args.force
        and result.get("status") == "complete"
        and result.get("script_version") == SCRIPT_VERSION
    ):
        print(f"skip complete: {model.name}")
        return

    cleanup_runtime(args)

    result["script_version"] = SCRIPT_VERSION
    result["model_id"] = model_id_for(model)
    result["model_path"] = str(model)
    result["status"] = "running"
    write_json(result_path, result)

    max_stable, coarse_successes = fit_sweep(args, model, result, result_path)
    run_parallel_matrix(args, model, result, result_path, max_stable, coarse_successes)

    result["status"] = "complete"
    write_json(result_path, result)


def main() -> int:
    args = parse_args()
    ensure_binary(args.bench_bin)
    ensure_binary(args.batched_bin)

    if args.summary_only:
        summary_path = summarize_results(args.results_dir)
        regenerate_charts(args)
        print(summary_path)
        return 0

    models = discover_models(args)
    if not models:
        print("No GGUF models found.", file=sys.stderr)
        return 1

    todo = []
    for model in models:
        result_path = result_path_for(args.results_dir, model)
        if args.force or not result_path.exists():
            todo.append(model)
            continue
        data = read_json(result_path)
        if data.get("status") != "complete" or data.get("script_version") != SCRIPT_VERSION:
            todo.append(model)

    print(f"discovered={len(models)} todo={len(todo)}")
    for model in todo:
        print(f"benchmarking {model.name}")
        run_model(args, model)

    summary_path = summarize_results(args.results_dir)
    regenerate_charts(args)
    print(f"summary={summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
