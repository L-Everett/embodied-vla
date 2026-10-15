#!/usr/bin/env bash
# 公共环境设置，被其它脚本 source。
# 自动适配 AutoDL（数据盘 /root/autodl-tmp + 学术加速）与普通 Linux。

# AutoDL 学术加速（GitHub / HuggingFace）
if [ -f /etc/network_turbo ]; then
  # shellcheck disable=SC1091
  source /etc/network_turbo 2>/dev/null || true
fi

# 数据根目录：AutoDL 用数据盘，否则用家目录
if [ -d /root/autodl-tmp ]; then
  DATA_ROOT="${DATA_ROOT:-/root/autodl-tmp}"
else
  DATA_ROOT="${DATA_ROOT:-$HOME}"
fi
export DATA_ROOT

export HF_HOME="${HF_HOME:-$DATA_ROOT/hf}"
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-$DATA_ROOT/.pip-cache}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
export MUJOCO_GL="${MUJOCO_GL:-egl}"
export WANDB_MODE="${WANDB_MODE:-disabled}"
export TOKENIZERS_PARALLELISM=false

mkdir -p "$HF_HOME" "$PIP_CACHE_DIR" 2>/dev/null || true
