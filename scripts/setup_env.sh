#!/usr/bin/env bash
# 环境安装：系统依赖 + conda 环境 + LeRobot（PyPI 国内源）
# 用法: bash scripts/setup_env.sh
# 说明: 自动适配 AutoDL（数据盘 /root/autodl-tmp、pip 清华源、代理只用于 GitHub）。
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/_env.sh

ENV_NAME="${ENV_NAME:-embvla}"
PY_VER="${PY_VER:-3.10}"
LEROBOT_SPEC="${LEROBOT_SPEC:-lerobot[libero,smolvla,pi,peft,evaluation]}"
PIP_INDEX="${PIP_INDEX:--i https://mirrors.aliyun.com/pypi/simple}"
# AutoDL 镜像自带 torch/CUDA，设 USE_BASE_ENV=1 直接复用，省去几 GB 下载
USE_BASE_ENV="${USE_BASE_ENV:-0}"

echo "==> 平台: DATA_ROOT=$DATA_ROOT (AutoDL=$([ -d /root/autodl-tmp ] && echo yes || echo no))"
echo "==> HF_HOME=$HF_HOME"

echo "==> [1/4] 系统依赖（EGL 渲染 + ffmpeg）"
if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi
$SUDO apt-get update
$SUDO apt-get install -y git ffmpeg build-essential libegl1 libgles2 libgl1 libglib2.0-0

echo "==> [2/4] conda 环境 $ENV_NAME (python $PY_VER)"
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
if [ "$USE_BASE_ENV" = "1" ]; then
  echo "    -> 复用 base 环境（镜像已带 torch/CUDA，省下载）"
  conda activate base
else
  if ! conda env list | grep -qE "/${ENV_NAME}\$"; then
    conda create -n "$ENV_NAME" "python=$PY_VER" -y
  fi
  conda activate "$ENV_NAME"
fi

echo "==> [3/4] 安装 LeRobot（PyPI 国内源）: $LEROBOT_SPEC"
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY 2>/dev/null || true
pip install -U pip $PIP_INDEX
pip install "$LEROBOT_SPEC" hf_transfer $PIP_INDEX

echo "==> [4/4] 环境变量（写入 ~/.bashrc）"
MARK="# >>> embodied-vla >>>"
if ! grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ""
    echo "$MARK"
    echo "export MUJOCO_GL=egl"
    echo "export HF_ENDPOINT=https://hf-mirror.com"
    echo "export HF_HOME=$HF_HOME"
    echo "export PIP_CACHE_DIR=$PIP_CACHE_DIR"
    echo "export WANDB_MODE=disabled"
    echo "export TOKENIZERS_PARALLELISM=false"
    echo "# <<< embodied-vla <<<"
  } >> "$HOME/.bashrc"
fi

echo
echo "完成。后续执行: source ~/.bashrc && conda activate $ENV_NAME"
python -c "import lerobot; print('lerobot ok', getattr(lerobot,'__version__',''))"
