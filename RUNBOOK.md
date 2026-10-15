# RUNBOOK —— 执行手册

> 目标：一台新的 **Linux + NVIDIA 24G** 实例上，从零到出结果，控制在预算内。
> 所有命令在仓库根目录执行。`$` 开头为 shell 命令。

---

## AutoDL 快速流程（本次实操）

> 镜像：`PyTorch 2.8.0 / py3.12 / cu12.8 / Ubuntu22.04`；卡：24GB（4090D/4090/3090）。
> 脚本已自适应 AutoDL：自动 `source /etc/network_turbo`、数据/缓存写 `/root/autodl-tmp`。

```bash
# 0) 已登录实例后
source /etc/network_turbo                       # GitHub/HF 加速（可重复执行）

# 1) 把仓库放到【数据盘】，相对路径自动落在数据盘
cd /root/autodl-tmp
git clone https://github.com/L-Everett/embodied-vla.git
cd embodied-vla

# 2) 装环境（apt 装 EGL + conda 建 embvla + LeRobot，pip 走清华源）
bash scripts/setup_env.sh
source ~/.bashrc && conda activate embvla

# 3) 预下载数据与模型（缓存到 /root/autodl-tmp/hf）
bash scripts/download_assets.sh

# 4) 冒烟测试
bash scripts/smoke.sh
```

**省钱要点**
- 环境配置 + 下载可改用**无卡模式**（约 0.1 元/h）完成，再切 GPU 跑训练/评测。
- 单次会话 ≤10h、空闲自动关机；结果都在 `/root/autodl-tmp`，关机不丢。
- 跑完务必把 `eval_logs/`、`outputs/` 下载回本地并**关机**。

---

## 0. 成本预算（开工前必读）

上一个 VLM 项目 20+ 元 ≈ 10~15 GPU 小时。本项目仿真评测吃时间，务必按下面**精简方案**跑。

### 方案 A（推荐，省预算）

| 步骤 | GPU 时间 |
|---|---|
| 环境 + 下载 | ~1.5 h |
| 冒烟 | ~0.3 h |
| SmolVLA 基线 400 ep | ~1.5 h |
| π0.5 基线 **仅 libero_spatial 100 ep**（认领前沿数字） | ~1 h |
| LoRA 微调 30k 步 | ~2 h |
| 微调后 400 ep | ~1.5 h |
| 域随机化 1 suite | ~1 h |
| 调试 buffer | ~3 h |
| **合计** | **~12 h** |

→ RTX 3090（1.2~1.7 元/h）：**~15~20 元**；RTX 4090（1.6~2.3 元/h）：**~19~28 元**。

### 方案 B（完整，预算充足再做）

π0.5 也跑满 400 ep（多花 ~3 h），总计 ~15~19 h。

### 结论

- **余额 25 元**：优先 **RTX 3090 / A10**，按方案 A 跑。
- 盯着用，`watch -n 60 nvidia-smi` 看利用率；不用时**立即关机**（数据盘通常保留）。

### 省钱守则

1. **一次下载到位**：所有数据/模型在 `download_assets.sh` 里一次拉完，避免来回等。
2. **结果增量落盘**：`eval_logs/`、`outputs/` 每步都写盘；即使掉线也能续。
3. **断点续跑**：训练用 `--save_freq` 定期存 checkpoint；评测按 suite 分开跑，跑完一个存一个。
4. **先冒烟后全量**：任何命令先用 `episodes=2` 试，确认无误再放大。
5. **关掉 wandb / 日志刷屏**：`WANDB_MODE=disabled`。
6. **别开图形界面**：一律 headless（EGL）。

---

## 1. 开实例前（本地准备）

- 把本仓库传到实例（二选一）：
  - `git init && git add . && git commit -m "init"` 后推到你的 GitHub，实例上 `git clone`；
  - 或用平台的上传功能。
- 记录平台**关机/删除**方式，确认数据盘持久化策略。

## 2. 实例开机后：环境

```bash
bash scripts/setup_env.sh
```

做的事情：apt 装 EGL/ffmpeg → conda 建 `embvla` 环境 → 装 LeRobot（`[libero,smolvla,pi,peft,evaluation]`）→ 写环境变量（`MUJOCO_GL=egl`、`HF_ENDPOINT=hf-mirror`）。

> 记得 `conda activate embvla`（脚本会提示）。

## 3. 预下载资产与模型

```bash
bash scripts/download_assets.sh
```

- 数据集 `lerobot/libero`（~1.9 GB，视频编码）
- 模型 `HuggingFaceVLA/smolvla_libero`（~1 GB）、`lerobot/pi05_libero_finetuned`（~7 GB）

## 4. 冒烟测试（必做，~20 min）

```bash
bash scripts/smoke.sh
```

预期：`libero_spatial/task_0` 跑 2 个 episode，打印成功率并保存视频到 `eval_logs/smoke/`。

> 若报 EGL 相关错 → 见「常见坑」第 1 条。

## 5. 基线评测（SmolVLA + π0.5）

```bash
# SmolVLA zero-shot，4 suite × 10 ep = 400 ep
bash scripts/eval_libero.sh "$DATA_ROOT/models/smolvla_libero" all 10 eval_logs/smolvla_zs

# π0.5 zero-shot（方案 A：只跑 spatial；方案 B：把 libero_spatial 改成 all）
bash scripts/eval_libero.sh "$DATA_ROOT/models/pi05_libero_finetuned" libero_spatial 10 eval_logs/pi05_zs --policy.n_action_steps=10
```

## 6. LoRA 微调 SmolVLA

```bash
STEPS=30000 RANK=32 bash scripts/train_lora.sh
```

产物：`outputs/smolvla_libero_lora/checkpoints/last/pretrained_model`。

## 7. 微调后评测

```bash
bash scripts/eval_libero.sh \
  outputs/smolvla_libero_lora/checkpoints/last/pretrained_model \
  all 10 eval_logs/smolvla_lora
```

## 8. 域随机化鲁棒性（Sim2Real 核心实验）

目标：量化策略在**视觉/物理扰动**下的成功率下降幅度。三种做法，按时间选：

1. **评测期视觉扰动**（最快）：在 `scripts/eval_libero.sh` 观测上加颜色抖动/背景替换，对比基线成功率；
2. **物理扰动**：改 LIBERO 场景的物体质量/摩擦参数后复测；
3. **多 seed 稳定性**：换 reset seed 重跑，看方差。

把两组数字填进 `docs/results.md`。

## 9. 收尾

```bash
python scripts/collect_results.py eval_logs   # 汇总成表
```
- 把表格 + rollout 视频下载回本地；
- 更新本仓库 `README.md` 的结果表、`docs/结果.md`；
- **关机**。

---

## 常见坑

1. **EGL 初始化失败**（`Cannot initialize a headless EGL display`）
   - 原因：缺 NVIDIA 用户态 GL 库（容器里常见）。
   - 解法：`sudo apt-get install -y libegl1 libgles2`；确认 `libEGL_nvidia.so.0` 在，且 `/usr/share/glvnd/egl_vendor.d/10_nvidia.json` 存在。实在不行退 `MUJOCO_GL=osmesa`（慢但能跑）。
2. **CUDA 与 EGL 抢显存**（小显存常见，24G 一般没事）
   - 症状：评测初始化崩溃。解法：`MUJOCO_GL=osmesa`，或用 LeRobot 的进程隔离评测。
3. **LIBERO 只能在 Linux**：Windows 不支持，必须 Linux 实例。
4. **`torchcodec` 装不上**：数据集用 `lerobot/libero`（视频编码）时需要；退而用 `HuggingFaceVLA/libero`（PNG，~70 GB，更大）。
5. **SmolVLA 相机数不匹配**（3 路 vs LIBERO 2 路）
   - 评测 `HuggingFaceVLA/smolvla_libero` 已适配；训练时若报错，加 `--policy.empty_cameras=1` 或用 `--rename_map`。
6. **π0.5 必须带 `--policy.n_action_steps=10`**，否则指标会明显偏低。
7. **速率限制/下载慢**：务必设 `HF_ENDPOINT=https://hf-mirror.com`。

## 关键参考

- LeRobot LIBERO 文档：https://huggingface.co/docs/lerobot/libero
- PEFT/LoRA 训练：https://huggingface.co/docs/lerobot/peft_training
- π0.5 文档：https://huggingface.co/docs/lerobot/pi05
- 低显存复现参考：https://github.com/2437buaa/smolvla-libero-repro
