#!/usr/bin/env bash
# 预下载数据集与模型：优先走魔搭（国内快），失败回退 HuggingFace。
# 用法: bash scripts/download_assets.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/_env.sh

MODELS="$DATA_ROOT/models"
DATASETS="$DATA_ROOT/datasets"
mkdir -p "$MODELS" "$DATASETS"
echo "HF_HOME=$HF_HOME  目标: $MODELS / $DATASETS"

ms_or_hf_model() {  # <repo> <local_dir>
  local repo="$1" dir="$2"
  echo "==> 模型 $repo -> $dir"
  if python scripts/ms_download.py "$repo" models "$dir"; then
    echo "   魔搭完成"
  else
    echo "   魔搭失败，回退 HuggingFace"
    python - "$repo" "$dir" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download(sys.argv[1], local_dir=sys.argv[2])
PY
  fi
}

ms_or_hf_dataset() {  # <repo> <local_dir>
  local repo="$1" dir="$2"
  echo "==> 数据集 $repo -> $dir"
  if python scripts/ms_download.py "$repo" datasets "$dir"; then
    echo "   魔搭完成"
  else
    echo "   魔搭失败，回退 HuggingFace"
    python - "$repo" "$dir" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download(sys.argv[1], repo_type="dataset", local_dir=sys.argv[2], max_workers=8)
PY
  fi
}

ms_or_hf_model  lerobot/smolvla_base            "$MODELS/smolvla_base"
ms_or_hf_model  HuggingFaceVLA/smolvla_libero   "$MODELS/smolvla_libero"
ms_or_hf_model  lerobot/pi05_libero_finetuned   "$MODELS/pi05_libero_finetuned"
ms_or_hf_dataset lerobot/libero                 "$DATASETS/libero"

echo
echo "全部完成。"
echo "  模型目录: $MODELS"
echo "  数据目录: $DATASETS/libero"
