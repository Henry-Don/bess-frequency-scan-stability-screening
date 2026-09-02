# 模型说明

[English](model_description.md) | **简体中文**

## 1. 用途

`models/bess_frequency_scan.slx` 是用于小信号频率响应辨识、弱电网交互风险筛查和时域交叉验证的独立跟网型电池储能系统模型。模型保留源 BESS 项目中已经验证的功率级与控制行为，同时增加了可重复的扰动接口。

## 2. 功率级

| 子系统 | 实现内容 |
|---|---|
| 电网 | 11 kV、50 Hz 三相电源，短路强度和 X/R 比可配置 |
| 交流接口 | 电压源变流器和 LCL 滤波器，经公共耦合点并网 |
| 直流母线 | 动态直流母线电容及电压测量 |
| 储能侧 | RC 电池模型和双向 DC/DC 变换 |
| 测量 | PCC 电压/电流、有功/无功、直流母线电压、电池电流和荷电状态 |

## 3. 控制结构

跟网型控制器使用 PLL 跟踪电网角度，并包含 abc/dq 变换、有功/无功与直流母线外环、dq 电流内环、限流和 anti-windup。荷电状态监督器对有功功率请求进行约束。控制结构见 [`control_architecture.svg`](control_architecture.svg)。

## 4. 频率扫描接口

d 轴测试施加小幅线路电压幅值调制，q 轴测试施加等效相位调制。每个频点先运行扰动关闭的基准工况，再分别运行 d 轴和 q 轴注入。脚本在整数周期分析窗内提取电压和电流复相量，从而辨识 dq 导纳矩阵的全部四个元素。

## 5. 可执行入口

| 任务 | 入口文件 |
|---|---|
| 初始化参数 | `scripts/init_frequency_scan.m` |
| 演示单个频点 | `scripts/run_single_frequency_demo.m` |
| 运行完整扫频 | `scripts/run_frequency_scan.m` |
| 筛查四档 SCR | `scripts/run_scr_interaction_scan.m` |
| 生成 PLL-SCR 风险地图 | `scripts/run_pll_risk_map.m` |
| 运行时域工况 | `scripts/run_time_domain_validation.m` |
| 执行全部检查 | `tests/run_all_checks.m` |

## 6. 数据与复现

运行时 MAT 文件和自动生成的图片写入 `results/`；仓库展示使用的精选证据复制到 `docs/images/`。频率扫描会保存每个已完成频点，并且仅在保存的配置签名与请求工况一致时恢复运行。

## 7. 解释边界

模型辨识的是指定运行点附近的仿真端口行为。报告分数是基于 `ZgridYbess` 最大奇异值的相对筛查指标，不构成正式广义 Nyquist 证明、硬件验证、保护研究或并网规范认证。
