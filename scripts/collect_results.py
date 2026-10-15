#!/usr/bin/env python
"""汇总 eval_logs/ 下 LeRobot 评测结果（eval_info.json）为成功率表格。

用法: python scripts/collect_results.py [eval_logs]

每个评测目录下 LeRobot 会写 eval_info.json，形如:
    {"libero_spatial": {"pc_success": 71.0, ...}, ..., "overall": {"pc_success": 68.3, ...}}
本脚本按"运行名"（相对 eval_logs 的目录名）聚合，输出各套件 + overall 成功率。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

SUITES = ["libero_spatial", "libero_object", "libero_goal", "libero_10"]


def load_success_map(path: Path) -> dict[str, float]:
    """从 eval_info.json 抽取 {suite_or_overall: pc_success}。"""
    try:
        data = json.loads(path.read_text())
    except Exception:
        return {}
    out: dict[str, float] = {}
    if not isinstance(data, dict):
        return out
    for key, val in data.items():
        if isinstance(val, dict) and isinstance(val.get("pc_success"), (int, float)):
            out[key] = float(val["pc_success"])
    return out


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "eval_logs")
    if not root.exists():
        print(f"[warn] {root} 不存在")
        return

    runs: dict[str, dict[str, float]] = {}
    for jf in sorted(root.rglob("eval_info.json")):
        m = load_success_map(jf)
        if not m:
            continue
        # 运行名 = 相对 root 的父目录路径
        rel = jf.parent.relative_to(root)
        runs[str(rel).replace("\\", "/") or jf.parent.name] = m

    if not runs:
        print("[info] 没找到 eval_info.json（评测可能还没跑完）")
        return

    cols = [*SUITES, "overall"]
    width = max(24, max((len(r) for r in runs), default=12) + 2)
    print(f"{'run':<{width}}" + "".join(f"{c:>16}" for c in cols))
    print("-" * (width + 16 * len(cols)))
    for run, m in runs.items():
        row = f"{run:<{width}}"
        for c in cols:
            row += f"{m[c]:>15.1f}%" if c in m else f"{'-':>16}"
        print(row)


if __name__ == "__main__":
    main()
