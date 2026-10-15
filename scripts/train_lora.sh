#!/usr/bin/env bash
# SmolVLA LoRA 微调（LeRobot PEFT）
# 用法: STEPS=30000 RANK=32 bash scripts/train_lora.sh
set -euo pipefail

STEPS="${STEPS:-30000}"
RANK="${RANK:-32}"
ALPHA="${ALPHA:-$RANK}"
LR="${LR:-1e-3}"
DECAY_LR="${DECAY_LR:-1e-4}"
BATCH="${BATCH:-32}"
OUT="${OUT:-outputs/smolvla_libero_lora}"

export MUJOCO_GL="${MUJOCO_GL:-egl}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
export WANDB_MODE="${WANDB_MODE:-disabled}"
mkdir -p "$OUT"

echo "==> LoRA r=$RANK alpha=$ALPHA steps=$STEPS batch=$BATCH out=$OUT"
lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=lerobot/libero \
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
