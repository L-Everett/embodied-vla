#!/usr/bin/env bash
# SmolVLA LoRA 微调（LeRobot PEFT）
# 用法: STEPS=30000 RANK=32 bash scripts/train_lora.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/_env.sh

STEPS="${STEPS:-30000}"
RANK="${RANK:-32}"
ALPHA="${ALPHA:-$RANK}"
LR="${LR:-1e-3}"
DECAY_LR="${DECAY_LR:-1e-4}"
BATCH="${BATCH:-32}"
OUT="${OUT:-outputs/smolvla_libero_lora}"
mkdir -p "$OUT"

BASE_MODEL="${SMOLVLA_BASE:-$DATA_ROOT/models/smolvla_base}"
DATA_ROOT_DIR="${LIBERO_DATA:-$DATA_ROOT/datasets/libero}"

echo "==> LoRA r=$RANK alpha=$ALPHA steps=$STEPS batch=$BATCH out=$OUT"
echo "    base=$BASE_MODEL  data=$DATA_ROOT_DIR"
lerobot-train \
  --policy.path="$BASE_MODEL" \
  --dataset.repo_id=lerobot/libero \
  --dataset.root="$DATA_ROOT_DIR" \
  --dataset.video_backend=torchcodec \
  --policy.output_features=null \
  --policy.input_features=null \
  --policy.optimizer_lr="$LR" \
  --policy.scheduler_decay_lr="$DECAY_LR" \
  --peft.method_type=LORA \
  --peft.r="$RANK" \
  --peft.lora_alpha="$ALPHA" \
  --batch_size="$BATCH" \
  --steps="$STEPS" \
  --save_freq="${SAVE_FREQ:-5000}" \
  --policy.push_to_hub=false \
  --output_dir="$OUT" \
  "$@" 2>&1 | tee "$OUT/train_$(date +%Y%m%d_%H%M%S).log"
