#!/usr/bin/env bash
# 通用 LIBERO 闭环评测
# 用法: bash scripts/eval_libero.sh <policy_path> <suites|all> <n_episodes> <output_dir> [透传 lerobot-eval 的额外参数...]
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/_env.sh

POLICY="${1:?policy_path 必填}"
SUITES_RAW="${2:-all}"
N_EPS="${3:-10}"
OUT="${4:-eval_logs/run}"
shift 4 || true

case "$SUITES_RAW" in
  all|ALL) SUITES="libero_spatial,libero_object,libero_goal,libero_10" ;;
  *)       SUITES="$SUITES_RAW" ;;
esac

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
