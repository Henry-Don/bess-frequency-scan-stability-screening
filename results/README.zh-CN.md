# 生成结果

[English](README.md) | **简体中文**

MATLAB 会将本地仿真数据和自动生成的图片写入本目录。二进制结果文件和运行时图片不纳入版本控制，因为它们可以通过 [`scripts/`](../scripts/) 下的脚本重新生成。

用于公开展示的精选图片保存在 [`docs/images/`](../docs/images/) 中，使 README、技术说明和项目网页保持可复现且体积适中。代表性输出包括单频响应、完整 dq 导纳、SCR 交互筛查、PLL-SCR 风险地图和时域验证。

运行 `tests/run_all_checks.m` 可以重新生成完整验证证据。
