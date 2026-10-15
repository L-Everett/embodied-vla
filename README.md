# embodied-vla

**可复现的具身智能 VLA 操作策略全链路 —— 在 MuJoCo/LIBERO 上跑通前沿 VLA 的闭环评测、LoRA 微调与域随机化鲁棒性分析。**

## 项目简介

通用 VLA（视觉-语言-动作）模型是具身智能的核心范式。本项目搭一条小而全、单卡可复现的流程，在 **LIBERO** 语言条件操作基准上：

1. **闭环评测基线** —— 用 LeRobot 在 LIBERO 4 个套件上评测 SmolVLA 与 π0.5（前沿对照）
2. **LoRA 微调** —— 用 PEFT/LoRA 对 SmolVLA 做高效适配，闭环评测对比
3. **域随机化鲁棒性** —— 对视觉/物理扰动做鲁棒性分析（Sim2Real 的核心矛盾）
4. **可视化** —— 保存 rollout 视频

> 评测是**闭环 rollout**（动作改变环境），指标是任务成功率，与离线 VLM 指标有本质区别。

## 结果

（跑通后填充，详见 [`docs/results.md`](docs/results.md)）

| 阶段 | LIBERO-Spatial | Object | Goal | Long | 平均 |
| --- | --- | --- | --- | --- | --- |
| SmolVLA zero-shot | - | - | - | - | - |
| π0.5 zero-shot | - | - | - | - | - |
| SmolVLA + LoRA | - | - | - | - | - |

## 快速开始

**先读 [`RUNBOOK.md`](RUNBOOK.md)**：含成本预算、逐步骤命令、省钱守则与常见坑。所有命令在仓库根目录执行。

### 0. 环境（Linux + NVIDIA GPU）

```bash
bash scripts/setup_env.sh          # 系统依赖 + conda 环境 + LeRobot(libero,smolvla,pi,peft)
bash scripts/download_assets.sh    # 预下载数据与模型（一次到位）
```

### 1. 冒烟测试

```bash
bash scripts/smoke.sh              # 单套件单任务少量 episode，验证闭环能跑通
```

### 2. 基线评测

```bash
# SmolVLA zero-shot，4 suite × 10 ep
bash scripts/eval_libero.sh "$DATA_ROOT/models/smolvla_libero" all 10 eval_logs/smolvla_zs

# π0.5 zero-shot（前沿对照；省预算可只跑 libero_spatial）
bash scripts/eval_libero.sh "$DATA_ROOT/models/pi05_libero_finetuned" all 10 eval_logs/pi05_zs --policy.n_action_steps=10
```

### 3. LoRA 微调

```bash
STEPS=30000 RANK=32 bash scripts/train_lora.sh
```

### 4. 微调后评测

```bash
bash scripts/eval_libero.sh outputs/smolvla_libero_lora/checkpoints/last/pretrained_model all 10 eval_logs/smolvla_lora
```

### 5. 域随机化鲁棒性

```bash
# 多 seed 稳定性复测（同一策略换 reset seed）
bash scripts/eval_robustness.sh HuggingFaceVLA/smolvla_libero libero_spatial 10 1000 2000 3000
```
视觉/物理扰动需在观测上打补丁，方法见 [`RUNBOOK.md`](RUNBOOK.md) 第 8 步。

### 6. 汇总结果

```bash
python scripts/collect_results.py eval_logs
```

## 目录结构

```
embodied-vla/
├── RUNBOOK.md            # 执行手册：预算、逐步骤命令、省钱守则、常见坑
├── scripts/
│   ├── _env.sh           # 公共环境（自动适配 AutoDL：数据盘 + 学术加速）
│   ├── setup_env.sh      # 环境安装
│   ├── download_assets.sh# 预下载数据/模型
│   ├── smoke.sh          # 冒烟测试
│   ├── eval_libero.sh    # 通用闭环评测（参数化 policy / suite / episodes）
│   ├── train_lora.sh     # SmolVLA LoRA 微调
│   ├── eval_robustness.sh# 多 seed 鲁棒性/稳定性复测
│   └── collect_results.py# 汇总 eval_info.json 为表格
├── eval_logs/            # 评测输出（gitignore）
├── outputs/              # 训练产物（gitignore）
└── docs/                 # 实验记录（results.md）
```

## 硬件

按**单张 24 GB 显卡**（RTX 3090/4090 级）设计；渲染用 EGL（GPU headless）。

## 上游项目

- [LeRobot](https://github.com/huggingface/lerobot) —— 训练/评测框架（Apache-2.0）
- [SmolVLA](https://huggingface.co/lerobot/smolvla_base) / [smolvla_libero](https://huggingface.co/HuggingFaceVLA/smolvla_libero)
- [π0.5](https://huggingface.co/docs/lerobot/pi05) / [LIBERO](https://github.com/Lifelong-Robot-Learning/LIBERO)
- [LIBERO dataset](https://huggingface.co/datasets/lerobot/libero)

## License

Apache-2.0
