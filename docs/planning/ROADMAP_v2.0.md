# LiquidGlassEffect v2.0 演进路线图 (Roadmap)

本文档详细描述了 `LiquidGlassEffect` 库的下一阶段扩展开发与优化方案。**v2.0 的核心目标是：在保持极致视觉效果的同时，实现生产级的性能表现和资源管理。**

## 1. 深度性能优化 (Deep Performance Optimization)

### 1.1 全局纹理池 (Global Texture Pool)
**问题**: 目前每个 `LiquidGlassView` 实例都维护自己的双缓冲纹理（`textureA`, `textureB`）。当页面存在大量小组件（如 TabBar Items, List Items）时，显存占用会线性增长，极易导致 OOM (Out Of Memory)。
**方案**:
- 实现 `LiquidGlassTexturePool` 单例，管理可复用的 `MTLTexture`。
- **复用策略**: 根据尺寸分桶（Bucketing），相同或相近尺寸的视图共享纹理缓存。
- **自动回收**: 监听内存警告和后台通知，自动释放未使用的纹理。
- **预期收益**: 显存占用降低 **60%-80%**（密集场景下）。

### 1.2 共享捕获上下文 (Shared Capture Context)
**问题**: 多个相邻的玻璃组件（如 TabBar 的 4 个按钮）各自截取背景，导致主线程重复执行昂贵的 `drawHierarchy`。
**方案**:
- 引入 `LiquidGlassGroup` 概念。
- **一次捕获，多次分发**: 父容器捕获一张大图，子组件根据坐标切片（Texture Slicing）或调整 UV 坐标来复用同一张纹理。
- **预期收益**: CPU 主线程负载降低 **N倍**（N=组件数量）。

### 1.3 静态快照机制 (Static Snapshotting)
**问题**: 即使画面静止，Metal 渲染循环仍在以 30fps/60fps 运行，持续消耗 GPU 和电量。
**方案**:
- **自动休眠**: 检测到画面无变化（无触摸、无滚动、无动画）超过 2 秒后，渲染最后一帧并缓存为静态图片。
- **停止管线**: 暂停 `CADisplayLink` 和 Metal 渲染循环。
- **即时唤醒**: 一旦检测到交互或属性变化，立即恢复渲染管线。
- **预期收益**: 静态场景下 GPU 占用降至 **0%**。

## 2. 视觉与交互增强 (Visual & Interaction)

### 2.1 交互式水波纹 (Interactive Ripple Effect)
**目标**: 让液态玻璃对用户的触摸产生真实的物理反馈。
- **功能**: 点击/拖拽生成向外扩散的正弦波纹，改变局部法线。
- **技术**: Fragment Shader 中叠加基于时间 `time` 的波纹函数偏移。

### 2.2 陀螺仪视差 (Gyroscope Parallax)
**目标**: 模拟真实玻璃在不同角度下的反光变化。
- **功能**: 利用 CoreMotion 监听设备姿态，实时调整 Shader 高光方向 (`glareDirectionOffset`)。

### 2.3 动态材质预设 (Dynamic Materials)
- **FrostedGlass**: 高频噪声纹理（磨砂感）。
- **IceBlock**: 内部气泡和裂纹。
- **OilSlick**: 增强色散和干涉条纹。

## 3. 工程化与稳定性 (Engineering & Stability)

### 3.1 智能降级策略 (Smart Fallback)
**目标**: 确保在极端环境下的可用性。
- **Low Power Mode**: 自动切换为系统级 `UIVisualEffectView` 或静态图片。
- **Reduce Motion**: 自动关闭光效流转和波纹动画。
- **Simulator**: 模拟器环境下自动回退到 CPU 模糊方案，避免 Metal 兼容性问题。

### 3.2 开发者体验 (DX)
- **Performance HUD**: 内置调试浮层，实时显示 FPS、显存占用、纹理数量。
- **Xcode Preview Helper**: 提供 Mock View 加速 SwiftUI 预览。

## 4. 实施计划 (Phasing)

| 阶段 | 重点 | 预计产出 |
| :--- | :--- | :--- |
| **Phase 1 (Performance)** | **显存与算力** | 纹理池、共享捕获、静态快照机制 |
| **Phase 2 (Visual)** | **交互增强** | 水波纹、陀螺仪、新材质 |
| **Phase 3 (Ecosystem)** | **组件与稳定** | 容器组件、智能降级、调试工具 |

---
*Created by Architect Agent for LiquidGlassEffect Team*
