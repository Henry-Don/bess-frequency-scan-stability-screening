# 跟网型 BESS 自动频率扫描与弱电网稳定风险筛查

[English](README.md) | **简体中文**

[![MATLAB R2024b](https://img.shields.io/badge/MATLAB-R2024b-e86b00?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/matlab.html)
[![Simulink and Simscape](https://img.shields.io/badge/Simulink%20%2B%20Simscape-validated-0076a8)](https://www.mathworks.com/products/simulink.html)
[![Frequency scan](https://img.shields.io/badge/frequency%20scan-20%20points-218739)](https://henry-don.github.io/bess-frequency-scan-stability-screening/)
[![Project validation](https://github.com/Henry-Don/bess-frequency-scan-stability-screening/actions/workflows/ci.yml/badge.svg)](https://github.com/Henry-Don/bess-frequency-scan-stability-screening/actions/workflows/ci.yml)

本项目在经过验证的 11 kV、50 Hz 并网电池储能系统（BESS）模型上增加可重复的小信号扰动接口，自动辨识完整黑盒 dq 导纳，筛查不同短路比（SCR）和 PLL 参数下的变流器—电网交互风险，并通过时域仿真交叉检查频域排序。

快速证据：[在线项目页](https://henry-don.github.io/bess-frequency-scan-stability-screening/) · [技术说明](docs/project_technical_guide.zh-CN.md) · [验证摘要](docs/verification_summary.zh-CN.md) · [模型说明](docs/model_description.zh-CN.md)

## 版本与范围

准备发布的版本为 **v1.0.0**。验证范围包含 0.5 Hz 至 100 Hz 的 20 个对数间隔频点、四档 SCR、四档 PLL 增益缩放以及独立的 d 轴/q 轴注入。完整 4 x 4 运行矩阵对应 640 次注入仿真；全部数值阈值均在矩阵比较前固定。

| 阶段 | 主要入口 | 已实现内容 |
| --- | --- | --- |
| 1 | `models/bess_frequency_scan.slx` | 独立模型、共享基准以及可控 d 轴/q 轴扰动接口 |
| 2 | `scripts/run_frequency_scan.m` | 可恢复的 20 点扫频以及完整 `Ydd`、`Ydq`、`Yqd`、`Yqq` 辨识 |
| 3 | `scripts/run_scr_interaction_scan.m` | SCR 10/5/3/2 电网阻抗、交互分数及关键频率提取 |
| 4 | `scripts/run_pll_risk_map.m` | 四档 PLL 增益缩放和 4 x 4 相对风险地图 |
| 5 | `scripts/run_time_domain_validation.m` | 三个代表性时域工况，包含超调、主导频率、衰减比和稳定状态 |
| 最终验证 | `tests/run_all_checks.m` | 拟合质量门槛、独立 10 Hz 重复性、基准等效及完整研究检查 |

## 系统与控制架构

### 物理系统

![并网 BESS 频率扫描架构](docs/system_architecture.svg)

11 kV BESS 被控对象包含从已验证源模型继承的 RC 电池、双向 DC/DC、真实直流母线、平均值 VSC、LCL 滤波器、跟网型控制和 PCC 测量。

### 频率扫描与控制系统

![跟网型 BESS 控制与频率扫描信号流](docs/control_architecture.svg)

扫频先运行共享的扰动关闭基准，再分别施加 d 轴幅值扰动和 q 轴相位扰动。最小二乘复相量提取形成完整的 dq 电压与电流矩阵；交互分数取 `Zgrid(jw) * Ybess(jw)` 的最大奇异值。方程、阈值和符号约定详见[技术说明](docs/project_technical_guide.zh-CN.md)。

## 模型视图

### 频率扫描 Simulink 模型

![Simulink 频率扫描顶层模型](docs/images/model_frequency_scan.png)

该图片直接由已保存的 `models/bess_frequency_scan.slx` 导出；发布流程不会保存或重新排列模型模块。

## 运行要求

| 组件 | 要求 | 已验证环境 |
| --- | --- | --- |
| MATLAB | 建议 MATLAB R2024b 或更高版本 | MATLAB 24.2（R2024b） |
| 必需建模产品 | Simulink、Simscape、Simscape Electrical | R2024b 产品 |
| Python | Python 3.10 或更高版本；仓库检查仅使用标准库 | 兼容 Python 3.11 |
| 操作系统 | MATLAB 支持的桌面操作系统；脚本使用仓库相对路径 | Windows 11 |

模型属于平均值系统研究，不需要开关器件模型或厂商专用控制库。

## 在线项目页与技术说明

![PLL 与 SCR 相对风险地图](docs/images/pll_scr_risk_map.png)

[在线项目页](https://henry-don.github.io/bess-frequency-scan-stability-screening/)集中展示架构、模型视图、主要图表和工程边界。详细说明提供中英文版本：

- [英文技术说明](docs/project_technical_guide.pdf)
- [中文技术说明](docs/project_technical_guide.zh-CN.pdf)
- [英文验证摘要](docs/verification_summary.md)
- [中文验证摘要](docs/verification_summary.zh-CN.md)

## 快速开始

1. 在仓库根目录打开 MATLAB，或将仓库根目录加入 MATLAB 路径。
2. 运行完整本地验证：

```matlab
run('tests/run_all_checks.m');
```

3. 打开 `models/bess_frequency_scan.slx` 查看模型。使用下列命令运行单个 10 Hz 辨识：

```matlab
run('scripts/run_single_frequency_demo.m');
```

生成的 MAT 文件和图片写入 `results/`。扫频会保存每个已完成频点，并且仅在保存的配置签名与请求工况一致时恢复。

## 回归验证

单阶段检查：

```matlab
run('tests/run_phase1_interface_check.m');
run('tests/run_phase1_repeatability_check.m');
run('tests/run_phase1_baseline_equivalence_check.m');
run('tests/run_phase2_frequency_scan_check.m');
run('tests/run_phase3_scr_interaction_check.m');
run('tests/run_phase4_pll_risk_map_check.m');
run('tests/run_phase5_time_domain_check.m');
```

分别运行主要研究：

```matlab
run_frequency_scan([]);
run_scr_interaction_scan;
run_pll_risk_map;
run_time_domain_validation;
```

持续验证使用的仓库检查入口为 `python/verify_repository.py`，用于确认公开文件结构并排除生成的 Simulink 缓存文件。

## 代表性结果

### 完整 dq 导纳

![dq 导纳四个元素的幅值与相位](docs/images/dq_admittance_response.png)

辨识结果保留包括交叉耦合在内的全部四个矩阵元素。完整扫频的最大主电压残差为 0.63%，最大加权电流残差为 14.23%，最大交叉电压泄漏为 3.29%，均满足设定的质量门槛。

### SCR 与 PLL 风险地图

![包含关键频率的 PLL-SCR 风险地图](docs/images/pll_scr_risk_map.png)

SCR 10 全部为 Lower，SCR 5 全部为 Moderate，SCR 3 和 SCR 2 在四档 PLL 参数下均为 Higher。关键交互频率集中在 57.25 Hz 至 100 Hz。

### 时域交叉检查

![三个时域验证工况](docs/images/time_domain_validation.png)

工况 A 计算为 Lower，工况 B 和 C 计算为 Higher。工况 B 原计划为 Moderate，但实际计算为 Higher，该结果被如实保留。超调排序在 3/3 个可比较对中与频域排序一致，衰减比排序在 2/3 个可比较对中一致；三个工况均未在 2.25 s 观察窗内进入 5% 稳定带。

## 当前验证结论与边界

完整本地入口显示 7/7 组检查通过。独立 10 Hz 重复性检查测得幅值漂移 0%、相位漂移 0 度；九路基准信号均满足设定的数值等效容差。验证版本中的 42 个 MATLAB 文件静态检查为零项问题。

风险等级是针对指定模型和运行点的相对指标，不构成正式广义 Nyquist 稳定性证书、开关谐波评估、厂商模型验证、硬件结果、保护配合研究或并网规范审批。

方法与结果见[技术说明](docs/project_technical_guide.zh-CN.md)，验收证据见[验证摘要](docs/verification_summary.zh-CN.md)，文件入口见[模型说明](docs/model_description.zh-CN.md)。

## 权利与使用

版权所有 © 2026 Henry Tang，保留所有权利。未经事先书面授权，不得复用、修改或再分发本仓库内容。本仓库不提供 `LICENSE` 文件。
