#!/usr/bin/env bash
# 预下载数据集与模型（一次到位，避免来回等）
# 用法: bash scripts/download_assets.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/_env.sh

echo "HF_HOME=$HF_HOME  HF_ENDPOINT=$HF_ENDPOINT  DATA_ROOT=$DATA_ROOT"

echo "==> 数据集 lerobot/libero (~1.9GB，视频编码，训练用)"
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("lerobot/libero", repo_type="dataset", max_workers=8)
print("dataset ok")
PY

echo "==> 模型 HuggingFaceVLA/smolvla_libero (~1GB)"
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("HuggingFaceVLA/smolvla_libero")
print("smolvla_libero ok")
PY

echo "==> 模型 lerobot/pi05_libero_finetuned (~7GB，仅评测用)"
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("lerobot/pi05_libero_finetuned")
print("pi05 ok")
PY

echo "==> 模型 lerobot/smolvla_base (~1GB，微调用)"
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("lerobot/smolvla_base")
print("smolvla_base ok")
PY

echo "全部下载完成。缓存位置: $HF_HOME"
