# 更新日志 (Changelog)

## [1.2.0] - 2026-02-04

### 🐛 缺陷修复 (Bug Fixes)
- **TabBar 动画修复**: 重构了 `LiquidGlassTabBar`, `LiquidGlassLabeledTabBar` 和 `LiquidGlassPillTabBar`，使用 `matchedGeometryEffect` 替代条件渲染，实现了选中气泡在 Tab 间的平滑流动动画。
- **点击穿透问题**: 修复了 `LiquidGlassView` 拦截下层视图点击事件的问题。现在通过重写 `hitTest`，允许点击事件穿透到背景层（除非点击的是其子视图）。
- **黑框/闪烁修复**: 
    - 增强了 Metal 渲染的异常处理，当纹理未就绪时不执行绘制，避免显示黑色背景。
    - 优化了应用从后台返回前台的恢复逻辑，强制预先捕获一次背景并延迟渲染，彻底解决了恢复时的黑框闪烁问题。

### ⚡️ 体验优化 (Improvements)
- **智能动态帧率**: 引入了位置变化检测机制。
    - **滑动时**: 自动检测视图位置变化，忽略节流限制，强制以 60fps 刷新背景，解决了滑动 ScrollView 时“背景滞后/带着走”的视觉延迟问题。
    - **静止时**: 自动恢复到低帧率（默认 30fps）模式，保持省电特性。
    - 无需手动介入，自动兼顾流畅性与续航。

## [1.1.0] - 2026-02-04

### 🚀 新特性 (Features)
- **背景捕获节流 (Background Capture Throttling)**: 新增 `backgroundCaptureFrameRate` 参数，允许开发者独立控制背景更新帧率（默认 30fps）。在不影响前景光效流畅度（60fps）的同时，大幅降低 CPU 占用。
- **性能优化 API**: 所有 UI 组件（`LiquidGlassCard`, `LiquidGlassButton`, `LiquidGlassSlider` 等）和 `liquidGlass()` modifier 均支持自定义背景捕获帧率。

### ⚡️ 性能优化 (Performance)
- **Shader 算法升级**: 优化了 `LiquidGlassShader.metal` 中的法线计算逻辑，从中心差分改为前向差分，减少了 50% 的 SDF 采样次数，显著降低 GPU 负载。
- **CPU 负载降低**: 默认启用的背景捕获节流机制使主线程 `drawHierarchy` 调用频率减半。

### 📱 演示应用 (Demo)
- 更新了 Demo 应用的 "Controls" 页面，增加了背景捕获帧率调节滑块，方便直观感受性能优化效果。
