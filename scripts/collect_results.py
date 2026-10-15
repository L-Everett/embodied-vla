#!/usr/bin/env python
"""汇总 eval_logs/ 下的评测结果为表格。

用法: python scripts/collect_results.py [eval_logs]

LeRobot 评测会把每个任务的成功等指标写成 JSON。本脚本递归扫描，
按顶层运行名（如 smolvla_zs / pi05_zs / smolvla_lora）聚合，输出各套件成功率。
不依赖具体目录结构，找不到指标就跳过。
"""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

SUITES = ["libero_spatial", "libero_object", "libero_goal", "libero_10"]
SUCCESS_KEYS = ["pc_success", "success_rate", "is_success", "avg_success"]


def find_success(obj):
    """在嵌套 dict 中找成功率字段，返回 (success_count, total) 或 None。"""
    if isinstance(obj, dict):
        # 优先找直接的百分比
        for k in ("pc_success", "success_rate", "avg_success"):
            if k in obj and isinstance(obj[k], (int, float)):
                return float(obj[k])
        # 找 n_episodes + success 计数
        n = obj.get("n_episodes")
        for k in ("success", "n_success", "num_success"):
            if k in obj and isinstance(obj[k], (int, float)) and n:
                return 100.0 * float(obj[k]) / float(n)
        for v in obj.values():
            r = find_success(v)
            if r is not None:
                return r
    elif isinstance(obj, list):
        for v in obj:
            r = find_success(v)
            if r is not None:
                return r
    return None


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "eval_logs")
    if not root.exists():
        print(f"[warn] {root} 不存在")
        return

    # run -> suite -> [success rates]
    runs: dict[str, dict[str, list[float]]] = defaultdict(lambda: defaultdict(list))

    for jf in root.rglob("*.json"):
        try:
            data = json.loads(jf.read_text())
        except Exception:
            continue
        val = find_success(data)
        if val is None:
            continue
        rel = jf.relative_to(root)
        run = rel.parts[0] if len(rel.parts) > 1 else jf.stem
        suite = next((s for s in SUITES if s in str(jf)), "overall")
        runs[run][suite].append(val)

    if not runs:
        print("[info] 没找到可解析的评测 JSON（评测可能还没跑完，或格式不同）")
        return

    header = ["run", *SUITES, "avg"]
    print(" | ".join(f"{h:>15}" for h in header))
    print("-" * (18 * len(header)))
    for run, suites in sorted(runs.items()):
        row = [run]
        allv = []
        for s in SUITES:
            vals = suites.get(s, [])
            if vals:
                m = sum(vals) / len(vals)
                row.append(f"{m:.1f}")
                allv.append(m)
            else:
                row.append("-")
        row.append(f"{sum(allv)/len(allv):.1f}" if allv else "-")
        print(" | ".join(f"{c:>15}" for c in row))


if __name__ == "__main__":
    main()
