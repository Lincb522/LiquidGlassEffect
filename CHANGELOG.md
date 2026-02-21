# 更新日志 (Changelog)

## [2.1.0] - 2026-02-05

### 🏗️ 架构重构 (Refactoring)
- **代码拆分**: 将 `LiquidGlassView` 中的背景捕获逻辑提取到独立的 `BackdropCapture` 类
- **模块化**: 
  - `LiquidGlassUniforms` 独立为单独文件，添加详细参数注释
  - `ShadowView` 从 `BackdropView` 中分离，支持自定义阴影参数
- **纹理池优化**: `LiquidGlassTexturePool` 添加缓存限制和 LRU 策略
- **引擎增强**: `LiquidGlassEngine` 添加线程安全锁，性能模式支持背景捕获率配置

### 🧩 组件增强 (Components)
- **新增组件**:
  - `LiquidGlassTextButton` - 简化的文本按钮
  - `LiquidGlassSecureField` - 密码输入框（带显示/隐藏切换）
  - `LiquidGlassLabeledToggle` - 带标签的开关
  - `LiquidGlassHorizontalSlider` - 水平滑块
  - `LiquidGlassBadge` - 数字徽章
  - `LiquidGlassToast` - 轻量级 Toast 提示
  - `LiquidGlassIndeterminateProgress` - 不确定进度指示器
- **按压样式**: 新增 `LiquidGlassPressableStyle` 统一管理按压动画参数
- **组件重构**: 所有组件代码风格统一，添加完整文档注释

### 📝 文档完善 (Documentation)
- 所有公开 API 添加 DocC 风格注释
- README 更新组件列表和项目结构
- 代码示例更新

### ⚡️ 性能优化 (Performance)
- `LiquidGlassView` 代码量从 ~400 行精简到 ~150 行
- 移除冗余的状态检查和重复代码

---

## [2.0.0] - 2026-02-04

### 🚀 架构升级 (Architecture)
- **全局纹理池 (Texture Pool)**: 引入 `LiquidGlassTexturePool` 单例，智能管理和复用 `MTLTexture`。
    - 根据尺寸和格式自动分桶复用，显著减少显存波动。
    - 自动响应内存警告，及时释放闲置资源。
- **共享背景上下文 (Shared Context)**: 新增 `LiquidGlassGroup` 容器组件。
    - **一次捕获，多次分发**: 容器内的所有子组件共享同一张背景纹理。
    - **性能飞跃**: 对于 TabBar、列表等密集场景，CPU 的 `drawHierarchy` 调用次数减少 70%-90%。
    - **UV 映射**: 子组件自动计算在大纹理中的相对坐标，无需手动干预。

### ⚡️ 性能优化 (Performance)
- **静态快照机制 (Static Snapshotting)**:
    - **自动冻结**: 检测到画面静止 2 秒后，自动截取最后一帧作为静态快照。
    - **零功耗**: 暂停 Metal 渲染循环 (`isPaused = true`)，将 GPU 占用降至 0%。
    - **即时唤醒**: 一旦检测到触摸或属性变化，立即恢复实时渲染，无缝衔接。

### 🛠 API 变更 (API Changes)
- 新增 `LiquidGlassGroup { ... }` 容器。
- `LiquidGlassModifier` 内部逻辑更新，支持可选的 `LiquidGlassGroupCoordinator` 注入。

---

## [1.2.0] - 2026-02-04

### 🐛 缺陷修复 (Bug Fixes)
- **TabBar 动画修复**: 重构了 `LiquidGlassTabBar`, `LiquidGlassLabeledTabBar` 和 `LiquidGlassPillTabBar`，使用 `matchedGeometryEffect` 替代条件渲染，实现了选中气泡在 Tab 间的平滑流动动画。
- **点击穿透问题**: 修复了 `LiquidGlassView` 拦截下层视图点击事件的问题。
- **黑框/闪烁修复**: 增强了 Metal 渲染的异常处理，优化了应用从后台返回前台的恢复逻辑。

### ⚡️ 体验优化 (Improvements)
- **智能动态帧率**: 引入了位置变化检测机制，滑动时自动升频至 60fps，静止时回落。

---

## [1.1.0] - 2026-02-04

### 🚀 新特性 (Features)
- **背景捕获节流**: 新增 `backgroundCaptureFrameRate` 参数，允许独立控制背景更新帧率。
- **性能优化 API**: 所有 UI 组件均支持自定义背景捕获帧率。

### ⚡️ 性能优化 (Performance)
- **Shader 算法升级**: 优化法线计算，减少 50% 的 SDF 采样次数。
