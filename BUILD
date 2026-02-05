# LiquidGlassEffect
# iOS 26 风格液态玻璃效果 Swift Package
# Credits: https://github.com/DnV1eX/LiquidGlassKit

## 概述

LiquidGlassEffect 是一个高性能的 iOS 液态玻璃效果库，基于 Metal 渲染，
提供类似 iOS 26 的液态玻璃 UI 效果。

## 版本

v2.1.0 (2026-02-05)

## 特性

- 🎨 Metal 渲染的液态玻璃效果
- 🚀 **高性能架构 (v2.x)**:
  - **共享背景上下文**: `LiquidGlassGroup` 让多组件共享单一背景捕获，CPU 负载降低 90%
  - **全局纹理池**: 智能显存管理，LRU 缓存策略
  - **静态快照**: 静止时 GPU 0% 占用
- 🏗️ **代码重构 (v2.1)**:
  - 核心代码模块化拆分
  - 完整的文档注释
  - 统一的按压动画样式
- 📱 iOS 15+ 支持
- 🎛️ 丰富的预设配置
- 🧩 SwiftUI 原生支持
- 📦 完整的 UI 组件库

## 安装

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Lincb522/LiquidGlassEffect", from: "2.1.0")
]
```

### 手动集成

将 `LiquidGlassEffect` 文件夹拖入项目即可。

## 库结构

```
LiquidGlassEffect/
├── Package.swift                    # SPM 配置
├── Sources/LiquidGlassEffect/
│   ├── LiquidGlassEffect.swift      # 库入口
│   ├── LiquidGlassShader.metal      # Metal 着色器
│   ├── Core/                        # 核心渲染
│   │   ├── LiquidGlassConfig.swift  # 配置
│   │   ├── LiquidGlassUniforms.swift # Shader 参数 (v2.1)
│   │   ├── LiquidGlassView.swift    # MTKView 实现
│   │   ├── LiquidGlassRenderer.swift # 渲染器
│   │   ├── LiquidGlassEngine.swift  # 性能引擎
│   │   ├── LiquidGlassTexturePool.swift # 纹理池
│   │   ├── LiquidGlassGroup.swift   # 共享上下文
│   │   ├── BackdropCapture.swift    # 背景捕获管理 (v2.1)
│   │   ├── BackdropView.swift       # CABackdropLayer
│   │   ├── ShadowView.swift         # 阴影视图 (v2.1)
│   │   └── ZeroCopyBridge.swift     # 零拷贝纹理桥
│   ├── SwiftUI/
│   │   ├── LiquidGlassModifier.swift # SwiftUI 修饰器
│   │   └── LiquidGlassEnvironment.swift # 环境变量
│   └── Components/                  # UI 组件
│       ├── LiquidGlassButton.swift  # 按钮
│       ├── LiquidGlassCard.swift    # 卡片/容器
│       ├── LiquidGlassFloatingBar.swift # 悬浮栏/TabBar
│       ├── LiquidGlassSlider.swift  # 滑块
│       ├── LiquidGlassTextField.swift # 输入框
│       ├── LiquidGlassToggle.swift  # 开关
│       ├── LiquidGlassTag.swift     # 标签/徽章
│       ├── LiquidGlassNotification.swift # 通知/Toast
│       ├── LiquidGlassProgress.swift # 进度条
│       ├── LiquidLensView.swift     # 动态镜头
│       └── PressableModifier.swift  # 按压效果 (v2.1)
└── Example/                         # 示例项目
    ├── project.yml
    ├── generate.sh
    ├── build_ipa.sh
    └── LiquidGlassDemo/
```

## 使用方法

### 基础用法

```swift
import SwiftUI
import LiquidGlassEffect

struct ContentView: View {
    var body: some View {
        Text("Hello")
            .padding()
            .liquidGlass()  // 应用液态玻璃效果
    }
}
```

### 共享背景上下文 (推荐用于复杂布局)

使用 `LiquidGlassGroup` 包裹多个玻璃组件，大幅提升性能：

```swift
LiquidGlassGroup {
    VStack {
        LiquidGlassCard { Text("Item 1") }
        LiquidGlassCard { Text("Item 2") }
        LiquidGlassCard { Text("Item 3") }
    }
}
// 此时只触发一次背景捕获，而不是三次
```

### 配置预设

```swift
// 标准效果
.liquidGlass(config: .regular)

// 镜头效果
.liquidGlass(config: .lens)

// 轻微效果
.liquidGlass(config: .subtle)

// 缩略图效果（适用于小组件）
.liquidGlass(config: .thumb())
```

### 组件库

#### 按钮

```swift
// 通用按钮
LiquidGlassButton(action: { }) {
    HStack {
        Image(systemName: "star.fill")
        Text("收藏")
    }
}

// 文本按钮
LiquidGlassTextButton("确定", action: { })

// 图标按钮
LiquidGlassIconButton(icon: "heart.fill", isActive: true, action: { })
```

#### 导航

```swift
// TabBar
LiquidGlassTabBar(
    selectedIndex: $selectedTab,
    items: [
        .init(id: 0, icon: "house", activeIcon: "house.fill"),
        .init(id: 1, icon: "magnifyingglass"),
        .init(id: 2, icon: "person", activeIcon: "person.fill")
    ]
)

// 带标签的 TabBar
LiquidGlassLabeledTabBar(
    selectedIndex: $selectedTab,
    items: [
        .init(id: 0, icon: "house", label: "首页"),
        .init(id: 1, icon: "gear", label: "设置")
    ]
)

// 悬浮栏
LiquidGlassFloatingBar {
    HStack { ... }
}
```

#### 表单

```swift
// 输入框
LiquidGlassTextField("搜索...", text: $searchText, icon: "magnifyingglass")

// 密码框
LiquidGlassSecureField("密码", text: $password)

// 开关
LiquidGlassToggle(isOn: $isEnabled, onColor: .green)

// 带标签的开关
LiquidGlassLabeledToggle("通知", subtitle: "接收推送通知", isOn: $notifyEnabled)

// 滑块
LiquidGlassSlider(value: $brightness, icon: "sun.max.fill")
```

#### 展示

```swift
// 标签
LiquidGlassTag("iOS 26", icon: "sparkles")

// 徽章
LiquidGlassBadge(count: 5)

// 通知卡片
LiquidGlassNotification(
    icon: "bell.fill",
    title: "通知",
    message: "新消息"
)

// Toast
LiquidGlassToast("已保存", icon: "checkmark")

// 进度条
LiquidGlassProgress(value: 0.7)
LiquidGlassCircularProgress(value: 0.5)
LiquidGlassIndeterminateProgress()
```

### 性能控制

```swift
// 设置性能模式
LiquidGlassEngine.shared.performanceMode = .balanced

// 可用模式:
// .quality    - 60fps 高质量
// .balanced   - 60fps 平衡 (默认)
// .efficiency - 30fps 省电
// .static     - 15fps 静态

// 控制背景捕获帧率
.liquidGlass(backgroundCaptureFrameRate: 15.0)
```

### 自定义配置

```swift
let customConfig = LiquidGlassConfig(
    uniforms: LiquidGlassUniforms(
        glassThickness: 8,
        refractiveIndex: 1.2,
        dispersionStrength: 10,
        glareIntensity: 0.15
    ),
    textureSizeCoefficient: 1.0,
    textureScaleCoefficient: 0.5,
    blurRadius: 0.2,
    shadowOverlay: true
)

Text("自定义")
    .liquidGlass(config: customConfig)
```

## API 参考

### LiquidGlassConfig

| 属性 | 类型 | 说明 |
|------|------|------|
| uniforms | LiquidGlassUniforms | Shader 参数 |
| textureSizeCoefficient | Double | 纹理尺寸系数 (1.0-1.2) |
| textureScaleCoefficient | Double | 纹理缩放系数 (0.5-1.0) |
| blurRadius | Double | 模糊半径 (0-20) |
| shadowOverlay | Bool | 是否显示阴影 |

### LiquidGlassUniforms

| 属性 | 类型 | 说明 |
|------|------|------|
| glassThickness | Float | 玻璃厚度 |
| refractiveIndex | Float | 折射率 (1.0=空气, 1.5=玻璃) |
| dispersionStrength | Float | 色散强度 |
| fresnelDistanceRange | Float | 菲涅尔距离 |
| fresnelIntensity | Float | 菲涅尔强度 |
| glareDistanceRange | Float | 眩光距离 |
| glareIntensity | Float | 眩光强度 |
| glareDirectionOffset | Float | 眩光方向偏移 |

### LiquidGlassPressableStyle (v2.1)

| 属性 | 类型 | 说明 |
|------|------|------|
| pressedScale | CGFloat | 按压缩放比例 |
| responseTime | Double | 动画响应时间 |
| dampingFraction | Double | 动画阻尼系数 |
| pressDuration | TimeInterval | 按压持续时间 |

预设样式: `.default`, `.subtle`, `.strong`, `.quick`

## 注意事项

1. **背景捕获延迟**: 使用 `drawHierarchy` 捕获背景有 1-2 帧延迟，这是 iOS 系统限制
2. **Metal 要求**: 需要支持 Metal 的设备
3. **内存管理**: 库会自动管理纹理缓存，在内存警告时释放

## 构建示例项目

```bash
cd LiquidGlassEffect/Example
./generate.sh      # 生成 Xcode 项目
./build_ipa.sh     # 构建 IPA
```

## 许可证

MIT License

## 致谢

- [LiquidGlassKit](https://github.com/DnV1eX/LiquidGlassKit) by Alexey Demin

## 致谢

- [LiquidGlassKit](https://github.com/DnV1eX/LiquidGlassKit) by Alexey Demin
