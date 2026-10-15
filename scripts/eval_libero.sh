#!/usr/bin/env bash
# 通用 LIBERO 闭环评测
# 用法: bash scripts/eval_libero.sh <policy_path> <suites|all> <n_episodes> <output_dir> [透传给 lerobot-eval 的额外参数...]
# 例:   bash scripts/eval_libero.sh HuggingFaceVLA/smolvla_libero all 10 eval_logs/smolvla_zs
#       bash scripts/eval_libero.sh lerobot/pi05_libero_finetuned libero_spatial 10 eval_logs/pi05_zs --policy.n_action_steps=10
set -euo pipefail

POLICY="${1:?policy_path 必填}"
SUITES_RAW="${2:-all}"
N_EPS="${3:-10}"
OUT="${4:-eval_logs/run}"
shift 4 || true

case "$SUITES_RAW" in
  all|ALL) SUITES="libero_spatial,libero_object,libero_goal,libero_10" ;;
  *)       SUITES="$SUITES_RAW" ;;
esac

export MUJOCO_GL="${MUJOCO_GL:-egl}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
mkdir -p "$OUT"

echo "==> policy=$POLICY suites=$SUITES n_episodes=$N_EPS out=$OUT extra=$*"
lerobot-eval \
  --policy.path="$POLICY" \
  --env.type=libero \
  --env.task="$SUITES" \
  --eval.batch_size="${EVAL_BATCH_SIZE:-1}" \
  --eval.n_episodes="$N_EPS" \
  --env.max_parallel_tasks=1 \
  --output_dir="$OUT" \
  "$@" 2>&1 | tee "$OUT/eval_$(date +%Y%m%d_%H%M%S).log"
