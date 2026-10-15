#!/usr/bin/env bash
# 鲁棒性 / 稳定性评测：同一策略换不同 reset seed 复测，量化成功率波动。
# 说明：视觉/物理扰动需要在观测上打补丁（见 RUNBOOK 第 8 步），本脚本负责多 seed 复测 + 结果落盘。
# 用法: bash scripts/eval_robustness.sh <policy_path> [suite] [n_episodes] [seed1 seed2 ...]
# 例:   bash scripts/eval_robustness.sh HuggingFaceVLA/smolvla_libero libero_spatial 10 1000 2000 3000
set -euo pipefail

POLICY="${1:?policy_path 必填}"
SUITE="${2:-libero_spatial}"
N="${3:-10}"
shift 3 || true
SEEDS=("$@")
if [ "${#SEEDS[@]}" -eq 0 ]; then SEEDS=(1000 2000 3000); fi

export MUJOCO_GL="${MUJOCO_GL:-egl}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
TAG="$(basename "$POLICY")"

for s in "${SEEDS[@]}"; do
  OUT="eval_logs/rob_${TAG}_seed${s}"
  mkdir -p "$OUT"
  echo "==> seed=$s suite=$SUITE n=$N -> $OUT"
  lerobot-eval \
    --policy.path="$POLICY" \
    --env.type=libero \
    --env.task="$SUITE" \
    --eval.batch_size=1 \
    --eval.n_episodes="$N" \
    --env.max_parallel_tasks=1 \
    --seed="$s" \
    --output_dir="$OUT" 2>&1 | tee "$OUT/eval.log"
done

echo
echo "==> 多 seed 汇总"
python scripts/collect_results.py eval_logs
