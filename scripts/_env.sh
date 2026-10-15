#!/usr/bin/env bash
# 公共环境设置，被其它脚本 source。
# 自动适配 AutoDL（数据盘 /root/autodl-tmp）与普通 Linux。
# 注意：不在全局开 network_turbo 代理——AutoDL 官方提示代理会让国内 pip/conda 源更慢。
#       只有访问 GitHub 时才临时开代理（见 setup_env.sh 的 clone 部分）。

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

# 关闭代理，保证国内 pip/conda 源速度（GitHub 相关见调用处临时开启）
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY 2>/dev/null || true

mkdir -p "$HF_HOME" "$PIP_CACHE_DIR" 2>/dev/null || true
