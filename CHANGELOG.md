# 更新日志 (Changelog)

## [1.1.0] - 2026-02-04

### 🚀 新特性 (Features)
- **背景捕获节流 (Background Capture Throttling)**: 新增 `backgroundCaptureFrameRate` 参数，允许开发者独立控制背景更新帧率（默认 30fps）。在不影响前景光效流畅度（60fps）的同时，大幅降低 CPU 占用。
- **性能优化 API**: 所有 UI 组件（`LiquidGlassCard`, `LiquidGlassButton`, `LiquidGlassSlider` 等）和 `liquidGlass()` modifier 均支持自定义背景捕获帧率。

### ⚡️ 性能优化 (Performance)
- **Shader 算法升级**: 优化了 `LiquidGlassShader.metal` 中的法线计算逻辑，从中心差分改为前向差分，减少了 50% 的 SDF 采样次数，显著降低 GPU 负载。
- **CPU 负载降低**: 默认启用的背景捕获节流机制使主线程 `drawHierarchy` 调用频率减半。

### 📱 演示应用 (Demo)
- 更新了 Demo 应用的 "Controls" 页面，增加了背景捕获帧率调节滑块，方便直观感受性能优化效果。
