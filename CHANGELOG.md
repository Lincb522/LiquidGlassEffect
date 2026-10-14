# 更新日志 (Changelog)

## [3.0.0] - 2026-10-14

光学与背景捕获重构，包含边缘专项 v2。

### 主版本迁移
- SwiftPM 依赖使用 `from: "3.0.0"` 或 `exact: "3.0.0"`；库内 `LiquidGlassEffectInfo.version` 同步为 `3.0.0`。
- 公开 `ZeroCopyBridge.render(actions:)` 回调现在使用 y 向下的绘图坐标；自行翻转坐标的调用方需重新核对。
- 原生按钮 action 不再由 `pressStyle.pressDuration` 延迟。预设、自定义光学参数及 `shadowOverlay` 行为需要视觉回归。
- 详见 [2.x → 3.0 迁移说明](docs/MIGRATING-3.0.md)。

### 边缘 v2 — iOS 18.4 完整回归通过
- 将指数白尾改为紧致 Gaussian 高光唇；默认风格约 0.6 point FWHM，结合像素 footprint 保持不同屏幕 scale 的稳定性。
- 独立计算约 1 point 深度的轻内暗谷；Fresnel 与方向高光合并为一次反射混合预算，避免重复叠白。
- 折射肩部通常限制在 2–5 point，独立保留主体散射深度；薄层位移乘连续衰减，厚度趋零时不跳变。中性透传及原始/柔化双纹理契约不变。
- 从玻璃表面移除 `ShadowView` 环影叠层，采用自身 layer 外投影；保留公开类型和 `shadowOverlay` 参数，并同步尺寸、同尺寸圆角、形状及开关变化。
- 默认圆角矩形使用匹配投影路径，自定义/合并/非圆曲率形状由实际 Metal alpha 生成投影；容器只裁内容，不裁玻璃唇与外投影。
- 新增 **4 项实际 GPU 边缘/薄层回归 + 2 项阴影几何/状态回归**，未改弱旧测试。
- 2026-10-14，Xcode 26.4 / iPhone 16 / iOS 18.4 Simulator 最终完整执行 **26/26 通过，0 失败、0 跳过**（23 项渲染/资源/阴影测试 + 3 项 UI 测试）。最终截图已检查；下方第一轮 20/20 是独立历史记录。

### 光学与材质
- 将 SDF、圆角、厚度和光学位移统一到 UIKit point 空间，修正控件尺寸影响边缘响应的问题。
- 分离原始背景与散射背景：边缘采样清晰纹理，内部采样 `MPSImageGaussianBlur` 生成的独立纹理。
- MPS blur 采用 out-of-place 目标，与玻璃采样置于同一 command buffer；保留原始捕获图。
- 重做受限折射、克制色散、方向高光、线性颜色混合及 premultiplied-alpha 抗锯齿边界。
- 重新校准 `.regular`、`.lens` 等预设。Regular 默认 blur 从 10 降为 5 point，Lens 保持零额外模糊；外观有意变化。

### 捕获、资源与实时更新
- 捕获帧携带 window-space 矩形，独立/分组通过统一 UV 映射读取正确区域，区分 overscan 与中心放大。
- 分组使用单个背景捕获循环，避免将前景玻璃和标签截回背景；同帧/同 sigma 共享模糊结果，子视图仍各自绘制。
- 用 Core Video pool 租借帧替代固定双缓冲覆盖，持有 pixel buffer/CV texture 到 GPU 使用完成；不把这些纹理归还普通 Metal 纹理池。
- 兼容裸纹理返回 API 复制到独立 Metal allocation，以保证返回值生命周期。
- SwiftUI `updateUIView` 将最新 config 应用到已有 `LiquidGlassView`，实时更新 tint、blur、圆角及相关资源。
- SwiftUI modifier 和组件的常用调用保持兼容；不承诺自定义光学参数的旧外观或所有低层 ABI 不变。

- 三类玻璃按钮改为原生 SwiftUI Button，以 isPressed 驱动 spring；保留构造 API，移除点击后的延迟动作。
- 共享 blur entry 保留弱 producer 与线程安全失败状态，晚到清理按 entry 身份执行，避免误删替换结果。

### Demo、测试与文档
- 保留五页组件画廊，增加 Optics 对照页和启动参数，覆盖浅/深色、动态背景、tint、圆角、分组和未覆盖背景参考。
- 增加实际 Metal/MPS、坐标、帧生命周期测试及可保留截图的 XCUITest。
- **第一轮历史结果（2026-10-14，边缘 v2 之前）：**iPhone 16 / iOS 18.4 Simulator 实际执行 **20/20 通过，0 跳过**（Xcode 26.4），并检查浅/深色与分组截图。这是当时版本的记录，不包含当前边缘 v2、外投影/裁剪改动或新增 6 项测试。最低部署版本继续为 iOS 15，其他 OS 与真机独立验收。
- 新增 [光学架构与验证方法](docs/OPTICS.md)，更新 README 与 BUILD；更正下方历史记录中的未验证性能百分比、自动冻结、GPU 零占用与 LRU 描述。
- 明确现有 `CABackdropLayer` 是私有 API，不承诺 App Store 接受；上游 README 声明 MIT，但当前取得的仓库缺少根目录 `LICENSE` 正文，本次没有补造许可文件。

---

## [2.1.0] - 2026-02-05

### 🏗️ 架构重构 (Refactoring)
- **代码拆分**: 将 `LiquidGlassView` 中的背景捕获逻辑提取到独立的 `BackdropCapture` 类
- **模块化**: 
  - `LiquidGlassUniforms` 独立为单独文件，添加详细参数注释
  - `ShadowView` 从 `BackdropView` 中分离，支持自定义阴影参数
- **纹理池优化（文档勘误）**: `LiquidGlassTexturePool` 提供分桶和缓存数量限制；源码没有按最近使用时间淘汰的 LRU 策略。
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
    - 根据尺寸、格式和 usage 分桶复用；实际显存变化需目标设备测量。
    - 自动响应内存警告，及时释放闲置资源。
- **共享背景上下文 (Shared Context)**: 新增 `LiquidGlassGroup` 容器组件。
    - **一次捕获，多次分发**: 容器内的所有子组件共享同一张背景纹理。
    - **性能描述勘误**: 共享捕获的目标是减少重复 `drawHierarchy` 调用；没有保留能支持原性能百分比的基准证据。
    - **UV 映射**: 子组件自动计算在大纹理中的相对坐标，无需手动干预。

### ⚡️ 性能优化 (Performance)
- **静态快照描述勘误**:
    - 原文将设想写成已经实现的自动静态检测与零功耗行为，现予更正。
    - `.static` 性能模式实际请求较低绘制/捕获频率，并不保证停止 GPU 工作。
    - 背景可能在控件位置不变时继续运动；当前捕获不会仅依据控件静止而冻结。

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
- **Shader 算法升级**: 调整法线计算；历史性能百分比缺少可复现测量记录，不作为当前效果承诺。
