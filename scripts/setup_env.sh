#!/usr/bin/env bash
# 环境安装：系统依赖 + conda 环境 + LeRobot（libero/smolvla/pi/peft）
# 用法: bash scripts/setup_env.sh
set -euo pipefail

ENV_NAME="${ENV_NAME:-embvla}"
LEROBOT_DIR="${LEROBOT_DIR:-$HOME/lerobot}"
LEROBOT_REF="${LEROBOT_REF:-}"   # 可选：填 commit/tag 以固定版本，如 v0.6.2

echo "==> [1/4] 系统依赖（EGL 渲染 + ffmpeg）"
if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi
$SUDO apt-get update
$SUDO apt-get install -y git ffmpeg build-essential libegl1 libgles2 libgl1 libglib2.0-0
# 低显存想用 CPU 渲染再加： $SUDO apt-get install -y libosmesa6

echo "==> [2/4] conda 环境 $ENV_NAME"
if ! conda env list | grep -qE "/${ENV_NAME}\$"; then
  conda create -n "$ENV_NAME" python=3.10 -y
fi
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

echo "==> [3/4] 安装 LeRobot"
if [ -d "$LEROBOT_DIR/.git" ]; then
  git -C "$LEROBOT_DIR" fetch --all --tags
else
  git clone https://github.com/huggingface/lerobot.git "$LEROBOT_DIR"
fi
if [ -n "$LEROBOT_REF" ]; then git -C "$LEROBOT_DIR" checkout "$LEROBOT_REF"; fi
pip install -U pip
pip install -e "${LEROBOT_DIR}[libero,smolvla,pi,peft,evaluation]"

echo "==> [4/4] 环境变量（写入 ~/.bashrc）"
MARK="# >>> embodied-vla >>>"
if ! grep -qF "$MARK" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'

# >>> embodied-vla >>>
export MUJOCO_GL=egl
export HF_ENDPOINT=https://hf-mirror.com
export HF_HOME=$HOME/.cache/huggingface
export WANDB_MODE=disabled
export TOKENIZERS_PARALLELISM=false
# <<< embodied-vla <<<
EOF
fi

echo
echo "完成。请执行: conda activate $ENV_NAME && source ~/.bashrc"
python -c "import lerobot; print('lerobot ok')"
