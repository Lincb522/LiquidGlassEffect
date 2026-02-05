# LiquidGlassDemo

LiquidGlassEffect example project (unsigned debug version).  
LiquidGlassEffect 示例项目（免签调试版）。

---

## Quick Start | 快速开始

### Generate Project | 生成项目

```bash
# Install XcodeGen first | 先安装 XcodeGen
brew install xcodegen

# Generate Xcode project | 生成 Xcode 项目
./generate.sh

# Open project | 打开项目
open LiquidGlassDemo.xcodeproj
```

### Build IPA | 构建 IPA

```bash
./build_ipa.sh
```

The IPA will be generated at `LiquidGlassDemo.ipa`.  
IPA 将生成在 `LiquidGlassDemo.ipa`。

---

## Installation Methods | 安装方式

### Simulator | 模拟器
Run directly in Xcode.  
直接在 Xcode 中运行。

### Real Device (Unsigned) | 真机（免签）

| Method | Requirement |
|--------|-------------|
| TrollStore | Install IPA directly |
| Sideloadly | Apple ID required |
| AltStore | Apple ID required |

| 方式 | 要求 |
|------|------|
| TrollStore | 直接安装 IPA |
| Sideloadly | 需要 Apple ID |
| AltStore | 需要 Apple ID |

---

## Project Configuration | 项目配置

The project is configured for unsigned debugging:  
项目已配置为免签调试模式：

```yaml
CODE_SIGN_IDENTITY: ""
CODE_SIGNING_REQUIRED: NO
CODE_SIGNING_ALLOWED: NO
```

---

## Demo Content | 演示内容

| Tab | Content | 内容 |
|-----|---------|------|
| Basic | Regular, Lens, Subtle presets | 三种预设效果对比 |
| Cards | Card layout examples | 卡片式布局示例 |
| Interactive | Buttons, tabs, sliders | 按钮、Tab、滑块等交互组件 |
| Config | Real-time parameter adjustment | 实时调整参数 |

---

## File Structure | 文件结构

```
Example/
├── project.yml          # XcodeGen config | XcodeGen 配置
├── generate.sh          # Generate script | 生成脚本
├── build_ipa.sh         # Build IPA script | 构建 IPA 脚本
└── LiquidGlassDemo/
    ├── LiquidGlassDemoApp.swift
    ├── ContentView.swift
    └── Assets.xcassets/
```

---

## Screenshots | 截图

Run the app to see the effects.  
运行应用查看效果。

| Basic | Cards | Interactive | Config |
|-------|-------|-------------|--------|
| 基础 | 卡片 | 交互 | 配置 |
