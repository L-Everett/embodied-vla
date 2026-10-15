#!/usr/bin/env bash
# 冒烟测试：单套件单任务少量 episode，验证闭环能跑通
# 用法: bash scripts/smoke.sh
set -euo pipefail

export MUJOCO_GL="${MUJOCO_GL:-egl}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
OUT="eval_logs/smoke"
mkdir -p "$OUT"

echo "==> 冒烟：libero_spatial/task_0 × 2 episodes"
lerobot-eval \
  --policy.path=HuggingFaceVLA/smolvla_libero \
  --env.type=libero \
  --env.task=libero_spatial \
  --env.task_ids="[0]" \
  --eval.batch_size=1 \
  --eval.n_episodes=2 \
  --env.max_parallel_tasks=1 \
  --output_dir="$OUT" 2>&1 | tee "$OUT/smoke_$(date +%Y%m%d_%H%M%S).log"

echo "冒烟完成。若成功率/视频正常，即可放大到 400 episode。"
