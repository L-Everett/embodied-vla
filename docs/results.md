# 实验结果

> 状态：待跑。跑完把数字填进来，并同步到仓库根 `README.md` 的结果表。

## 1. 基线（zero-shot）

| 模型 | Spatial | Object | Goal | Long | 平均 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| SmolVLA (`HuggingFaceVLA/smolvla_libero`) | - | - | - | - | - | 4 suite × 10 ep |
| π0.5 (`lerobot/pi05_libero_finetuned`) | - | - | - | - | - | `n_action_steps=10` |

## 2. LoRA 微调

| 配置 | Spatial | Object | Goal | Long | 平均 |
| --- | --- | --- | --- | --- | --- |
| SmolVLA zero-shot | - | - | - | - | - |
| + LoRA r=__ steps=__ | - | - | - | - | - |

超参记录：`--peft.method_type=LORA --peft.r=__ --peft.lora_alpha=__ --policy.optimizer_lr=__ --batch_size=__ --steps=__`

## 3. 鲁棒性 / 稳定性（Sim2Real 近似度量）

**方法**：同一策略、同一 suite，换 reset seed 复测（`scripts/eval_robustness.sh`），看成功率波动；
再对观测做视觉扰动 / 场景加物理扰动（需在观测上打补丁，见 RUNBOOK 第 8 步），看成功率下降幅度。

| 条件 | Spatial 成功率 | 相对基线下降 |
| --- | --- | --- |
| seed 1000（基线） | - | - |
| seed 2000 | - | - |
| seed 3000 | - | - |
| 视觉扰动（颜色/背景） | - | - |
| 物理扰动（质量/摩擦） | - | - |

**结论/解释**：（待填）

## 4. 复现环境

| 项 | 值 |
| --- | --- |
| GPU | - |
| 渲染后端 | EGL |
| LeRobot 版本 / commit | - |
| MuJoCo 版本 | - |
| 评测 episode 数 | 400（4 suite × 10 task × 10 ep） |

## 5. 踩坑记录

- （待填）
