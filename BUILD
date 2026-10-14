# LiquidGlassEffect — 构建与集成

这是 Markdown 文档，不是构建系统的 `BUILD` 配置文件。项目使用 Swift Package Manager；示例 App 的 Xcode 工程由 XcodeGen 生成。

本构建说明对应 **3.0.0**。从 2.x 升级请先阅读 [迁移说明](docs/MIGRATING-3.0.md)。SwiftUI modifier 和组件的常用调用方式保留，预设外观已经重新校准。架构与验证细节见 [docs/OPTICS.md](docs/OPTICS.md)。

## 要求与验证范围

- Swift 5.9+，具有对应 iOS SDK 的 Xcode。
- Package 和示例的 iOS deployment target 保持 **15.0**。
- 渲染要求 Metal；Gaussian blur 复用系统 Metal Performance Shaders。
- 示例工程生成需要 XcodeGen。
- **当前边缘 v2：**2026-10-14，Xcode 26.4 / iPhone 16 / iOS 18.4 Simulator 最终完整执行 **26/26 通过，0 失败、0 跳过**（23 项渲染/资源/阴影测试 + 3 项 UI 测试）。先由脚本执行全新 DerivedData 构建；修正薄层连续性与新测试浮点容差后，在同一 DerivedData 完整重测。
- **第一轮历史记录（边缘 v2 之前，2026-10-14）：**Xcode 26.4 / iPhone 16 / iOS 18.4 Simulator，`scripts/test-ios18.sh` 从干净 DerivedData 执行 **20/20 通过，0 跳过**。该记录不覆盖本次 v2 shader、外投影/裁剪调整及新增 6 项测试，也不代表其他系统或真机已经验收。
- 背景捕获依赖私有 `CABackdropLayer`。构建成功、模拟器运行和 App Store 审核接受是不同事项；本项目没有审核通过承诺。

## 本地 package 集成

使用 Xcode 的 **Add Local Package** 选择仓库，或添加：

```swift
.package(path: "../LiquidGlassEffect")
```

不要仅复制 Swift 源文件而遗漏 `LiquidGlassShader.metal` 的 package resource。

3.0.0 的远程依赖方式：

```swift
.package(url: "https://github.com/Lincb522/LiquidGlassEffect.git", from: "3.0.0")
```

需要固定本次发布时使用 `exact: "3.0.0"`；2.x 版本约束不会自动跨主版本。

## 生成与构建 Demo

在仓库根目录执行：

```bash
cd Example
xcodegen generate
xcodebuild build \
  -project LiquidGlassDemo.xcodeproj \
  -scheme LiquidGlassDemo \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

或者打开 `LiquidGlassDemo.xcodeproj`，选择已安装的模拟器后运行。示例保留五个组件页面，右上角 **Optics** 打开真实 Metal 光学对照页。

## iOS 18 模拟器测试

先确认实际存在的 iOS 18 设备：

```bash
xcrun simctl list devices available
```

将下面的 `SIMULATOR_UDID` 替换为对应标识符，在 `Example` 目录执行：

```bash
xcodebuild test \
  -project LiquidGlassDemo.xcodeproj \
  -scheme LiquidGlassDemo \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -resultBundlePath /tmp/LiquidGlassEffect-iOS18.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

`-resultBundlePath` 应使用尚未存在的路径；多次运行保留不同结果包，不覆盖旧证据。

Scheme 包含：

| Target | 内容 |
|---|---|
| `LiquidGlassEffectTests` | App-hosted XCTest，实际 Metal shader、MPS、采样映射、Core Video 资源生命周期与阴影路径/状态测试 |
| `LiquidGlassDemoUITests` | App 启动、光学开关、原画廊按钮，以及保留的截图附件 |

通过 `-only-testing:LiquidGlassEffectTests` 或 `-only-testing:LiquidGlassDemoUITests` 可分别执行。运行结果以 Xcode 的实际 test report 为准；代码静态检查、build、test、视觉评审和真机验收分别记录。

## 光学对照启动参数

在 Scheme 的 Run Arguments 中设置，或安装 App 后通过 `simctl launch` 传入：

| 参数 | 初始状态 |
|---|---|
| `--optics` | 直接进入光学对照页 |
| `--optics-dark` | 深色背景 |
| `--optics-tint` | 蓝色 shader material tint |
| `--optics-angular` | 小圆角 |
| `--optics-grouped` | 使用 `LiquidGlassGroup` |
| `--optics-motion` | 背景文字、网格与蓝条移动 |
| `--optics-no-glass` | 隐藏玻璃，保留原背景作参考 |

附加参数与 `--optics` 组合。页面内六个按钮可实时切换；无需重启或 `.id(...)` 重建。

## 当前实现契约

### 捕获与纹理

- 独立视图通过位于玻璃后方的 backdrop layer 捕获背景。
- 分组通过一个 30 fps 捕获循环生成共享帧。共享帧不含该组的前景文字和玻璃本身；应在目标系统的截图中验证这一点。
- `CapturedBackdrop` 将纹理、window-space 捕获矩形、`CVPixelBuffer` 与 `CVMetalTexture` 一起持有，GPU completion 后释放使用中的帧引用。
- 原始纹理与模糊纹理分离。MPS out-of-place blur 与首个消费者同一 command buffer；组内同帧/同 sigma 复用输出，通过共享有序队列保持生产先于消费。
- 普通 `LiquidGlassTexturePool` 仍保留分桶/数量上限 API；捕获帧不走该池，也不存在文档所曾声称的 LRU 实现。

### 边缘 v2 与阴影契约

- 高光为以 point 定义的紧致 Gaussian 唇，默认参数约为 0.6 point FWHM；抗锯齿像素 footprint 参与宽度，避免 2x/3x 下直接按固定像素形成不同粗细。
- 内暗谷单独以约 1 point 深度为中心，不再沿用明亮边缘的衰减曲线；默认风格要求约 2 point 后接近原背景，数值边界由新 GPU 剖面测试检查，最终 GPU 测试已执行通过。
- Fresnel 和 directional glare 先合并为一个有上限的反射预算，再进行一次亮色混合，避免两次叠白；中性光学参数继续遵循原色透传契约。
- 折射肩部由厚度派生并限制在通常 2–5 point（极小表面还受半尺寸约束）；主体散射使用独立 optical depth，不以收窄高光为由消除原始边缘/柔化主体分层。
- `LiquidGlassView` 不再在表面添加 `ShadowView` 环影子视图；自身 layer 使用轻微外投影，保留 `shadowOverlay` 开关。默认圆角矩形具有匹配的 `shadowPath`；自定义、多形状或非圆曲率轮廓由实际 Metal alpha 决定投影。
- 圆角、尺寸、形状与阴影开关变化需更新外投影路径；同尺寸圆角变化也须立即生效。
- `LiquidGlassContainer` 先裁剪前景 content，再添加玻璃 background。不要在整个玻璃容器之后追加 `.clipShape(...)` / `.clipped()`，否则外投影和抗锯齿唇仍会被调用方裁掉。

新增回归包括 4 项真实 GPU 边缘/薄层剖面测试（深灰紧致高光、白底内暗谷、2x/3x point 一致性、厚度趋零的连续折射），以及 2 项 UIKit/Metal 视图阴影测试（尺寸/圆角/开关同步、自定义形状与默认路径恢复）。最终 26 项结果包含这些新增回归；代码覆盖范围不替代设备和视觉验收。

### 坐标与配置

- 几何和 SDF 使用 UIKit point；frame 的捕获坐标统一转换到 window space。
- 独立/分组共用 UV 映射；overscan 不应导致无意缩小背景，`thumb(magnification:)` 则有明确的中心放大采样。
- SwiftUI `updateUIView` 调用 `updateConfiguration`。更新 tint/blur 等材质参数时保留 native view，捕获尺寸改变时重建相应捕获资源。
- `textureSizeCoefficient`、`textureScaleCoefficient` 必须为有限正数，`blurRadius` 必须是有限非负数，`thumb` magnification 必须为有限正数；非法配置会明确触发前置条件错误。

### 性能模式不是冻结保证

| 模式 | 请求绘制 fps | 引擎配置的独立捕获 fps |
|---|---:|---:|
| `.quality` | 60 | 60 |
| `.balanced` | 60 | 30 |
| `.efficiency` | 30 | 20 |
| `.static` | 15 | 10 |

`backgroundCaptureFrameRate`、引擎模式设置与实际设备调度均会影响观察结果。分组捕获当前独立使用 30 fps。`.static` 不是零绘制模式，也不检测背景像素是否静止；禁止从名称推断 GPU 零占用。

## 分发和许可边界

现有 `Example/build_ipa.sh` 属于示例打包流程。产出 archive 或 IPA 只证明相应构建步骤完成，不证明已签名可安装、TestFlight 可用或商店接受。由于捕获采用私有 API，分发方式需独立核实。

上游 README 声明 MIT，但当前取得的上游/checkout 缺少根目录 `LICENSE` 正文。本次没有生成许可证文件或改变许可结论。

## 进一步阅读

- [README](README.md)：接口和组件概览。
- [Optics](docs/OPTICS.md)：原理、限制和可复现验证流程。
- [Example README](Example/README.md)：Demo 控件和测试入口。
- [Changelog](CHANGELOG.md)：3.0.0 改动和历史记录。
