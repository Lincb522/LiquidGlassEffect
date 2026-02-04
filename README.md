# LiquidGlassEffect

iOS 26 风格液态玻璃效果 Swift Package，基于 Metal 高性能渲染。

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 特性

- 🎨 Metal 渲染的液态玻璃效果
- 🚀 高性能双缓冲纹理机制与智能节流（默认 30fps 背景捕获，60fps 光效渲染）
- 📱 iOS 15+ 支持
- 🎛️ 丰富的预设配置（regular、lens、subtle、thumb）
- 🧩 SwiftUI 原生支持
- 📦 完整的 UI 组件库

## 安装

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Lincb522/LiquidGlassEffect", from: "1.2.0")
]
``````

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

## 组件

| 组件 | 说明 |
|------|------|
| `LiquidGlassButton` | 液态玻璃按钮 |
| `LiquidGlassCard` | 液态玻璃卡片 |
| `LiquidGlassTabBar` | iOS 26 风格 TabBar |
| `LiquidGlassSlider` | 滑块控件 |
| `LiquidGlassTextField` | 输入框 |
| `LiquidGlassToggle` | 开关 |
| `LiquidGlassTag` | 标签 |
| `LiquidGlassNotification` | 通知卡片 |
| `LiquidGlassProgress` | 进度条 |

## 配置预设

```swift
.liquidGlass(config: .regular)   // 标准效果
.liquidGlass(config: .lens)      // 镜头效果
.liquidGlass(config: .subtle)    // 轻微效果
.liquidGlass(config: .thumb())   // 缩略图效果
```

## 性能优化

从 v1.1.0 开始，你可以控制背景捕获的帧率以节省电量：

```swift
// 背景每秒更新 15 次，但光效依然保持 60fps 流畅
.liquidGlass(backgroundCaptureFrameRate: 15.0)
```

## 致谢

- [LiquidGlassKit](https://github.com/DnV1eX/LiquidGlassKit) by Alexey Demin

## 许可证

MIT License
