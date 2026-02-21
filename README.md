# LiquidGlassEffect

iOS 26 风格液态玻璃效果 Swift Package，基于 Metal 高性能渲染。

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 效果展示 (Previews)

| Button 按钮 | Card 卡片 | 动态演示 |
|:---:|:---:|:---:|
| <img src="docs/assets/demo_buttons.jpg" width="240" alt="LiquidGlass Button"> | <img src="docs/assets/demo_cards.png" width="240" alt="LiquidGlass Card"> | [点击观看视频演示](docs/assets/demo_video.mp4) |

## 🔥 最新动态 (What's New)

### v2.1.0 - 代码重构与组件增强
- **🏗️ 架构重构**: 核心代码拆分为独立模块，提升可维护性
- **🧩 组件增强**: 新增 `LiquidGlassTextButton`、`LiquidGlassSecureField`、`LiquidGlassToast` 等组件
- **� 完整文档**: 所有公开 API 添加详细注释
- **🎯 按压样式**: 新增 `LiquidGlassPressableStyle` 统一按压动画配置

### v2.0.0 - 性能架构大升级
- **� 共享背景上下文**: `LiquidGlassGroup` 多组件共享背景捕获，CPU 负载降低 90%
- **� 全局纹理池**: 智能显存管理，自动复用纹理
- **⚡️ 静态快照**: 画面静止时自动冻结渲染，GPU 0% 占用

## 特性

- 🎨 Metal 渲染的液态玻璃效果
- 🚀 高性能双缓冲纹理机制与智能节流
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

## 快速开始

```swift
import SwiftUI
import LiquidGlassEffect

struct ContentView: View {
    var body: some View {
        Text("Hello, Liquid Glass!")
            .padding()
            .liquidGlass()
    }
}
```

## 组件库

### 基础组件

| 组件 | 说明 |
|------|------|
| `LiquidGlassButton` | 通用按钮（支持自定义内容） |
| `LiquidGlassTextButton` | 文本按钮 |
| `LiquidGlassIconButton` | 图标按钮 |
| `LiquidGlassCard` | 卡片容器 |
| `LiquidGlassContainer` | 基础容器 |

### 导航组件

| 组件 | 说明 |
|------|------|
| `LiquidGlassTabBar` | iOS 26 风格 TabBar |
| `LiquidGlassLabeledTabBar` | 带标签的 TabBar |
| `LiquidGlassPillTabBar` | 药丸形 TabBar |
| `LiquidGlassFloatingBar` | 悬浮工具栏 |

### 表单组件

| 组件 | 说明 |
|------|------|
| `LiquidGlassTextField` | 文本输入框 |
| `LiquidGlassSecureField` | 密码输入框 |
| `LiquidGlassToggle` | 开关 |
| `LiquidGlassLabeledToggle` | 带标签的开关 |
| `LiquidGlassSlider` | 垂直滑块 |
| `LiquidGlassHorizontalSlider` | 水平滑块 |

### 展示组件

| 组件 | 说明 |
|------|------|
| `LiquidGlassTag` | 标签 |
| `LiquidGlassBadge` | 徽章 |
| `LiquidGlassNotification` | 通知卡片 |
| `LiquidGlassToast` | Toast 提示 |
| `LiquidGlassProgress` | 线性进度条 |
| `LiquidGlassCircularProgress` | 圆形进度 |
| `LiquidGlassIndeterminateProgress` | 不确定进度 |

## 配置预设

```swift
.liquidGlass(config: .regular)   // 标准效果
.liquidGlass(config: .lens)      // 镜头效果
.liquidGlass(config: .subtle)    // 轻微效果
.liquidGlass(config: .thumb())   // 缩略图效果
```

## 性能控制

```swift
// 控制背景捕获帧率
.liquidGlass(backgroundCaptureFrameRate: 15.0)

// 全局性能模式
LiquidGlassEngine.shared.performanceMode = .efficiency
```

## 项目结构

```
Sources/LiquidGlassEffect/
├── Core/                    # 核心渲染
│   ├── LiquidGlassView.swift
│   ├── LiquidGlassRenderer.swift
│   ├── LiquidGlassEngine.swift
│   ├── LiquidGlassConfig.swift
│   ├── LiquidGlassUniforms.swift
│   ├── LiquidGlassTexturePool.swift
│   ├── BackdropCapture.swift
│   ├── BackdropView.swift
│   ├── ShadowView.swift
│   └── ZeroCopyBridge.swift
├── SwiftUI/                 # SwiftUI 集成
│   ├── LiquidGlassModifier.swift
│   └── LiquidGlassEnvironment.swift
├── Components/              # UI 组件
│   ├── LiquidGlassButton.swift
│   ├── LiquidGlassCard.swift
│   ├── LiquidGlassFloatingBar.swift
│   ├── LiquidGlassSlider.swift
│   ├── LiquidGlassTextField.swift
│   ├── LiquidGlassToggle.swift
│   ├── LiquidGlassTag.swift
│   ├── LiquidGlassNotification.swift
│   ├── LiquidGlassProgress.swift
│   ├── LiquidLensView.swift
│   └── PressableModifier.swift
└── LiquidGlassShader.metal  # Metal Shader
```

## 致谢

- [LiquidGlassKit](https://github.com/DnV1eX/LiquidGlassKit) by Alexey Demin

## 许可证

MIT License
