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
| Buttons | Buttons, icons and press interactions | 按钮与按压交互 |
| Cards | Cards, notifications, tags and badges | 卡片、通知、标签和角标 |
| Forms | Text fields, sliders and toggles | 输入框、滑块和开关 |
| Progress | Linear, circular and indeterminate progress | 进度组件 |
| Navigation | Tab bars and floating containers | 导航栏和浮动容器 |

### Optical comparison | 光学对照

Tap **Optics** in the gallery, or launch with `--optics`. This page uses the
library's actual Metal glass over a deterministic grid, letterforms and solid
blue/orange shapes. Regular and Lens are shown side by side, followed by round,
capsule and wide surfaces. The exposed background is the visual reference.

点击画廊右上角 **Optics**，或使用 `--optics` 启动。对照页使用本库真实的 Metal
渲染，在网格、文字和蓝橙色块上展示 Regular、Lens、圆形、胶囊及宽面板。
观察玻璃内外网格的连续性、边缘折射及 Regular / Lens 的细节差异。

| Launch argument | Initial state |
|---|---|
| `--optics` | Open the optical comparison |
| `--optics-dark` | Dark appearance |
| `--optics-tint` | Blue material tint passed into the shader |
| `--optics-angular` | Smaller corner radii |
| `--optics-grouped` | Shared background capture via `LiquidGlassGroup` |
| `--optics-motion` | Moving text, grid and blue stripe |
| `--optics-no-glass` | Uncovered background reference |

Combine these arguments with `--optics`. All six controls also work while the
page is running; no view identity reset is used to update tint or corners.

### Simulator tests | 模拟器测试

Generate the project, then run the shared `LiquidGlassDemo` scheme with an
installed iOS 18 simulator (replace `SIMULATOR_UDID` with its identifier):

```bash
xcodegen generate
xcodebuild test \
  -project LiquidGlassDemo.xcodeproj \
  -scheme LiquidGlassDemo \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  CODE_SIGNING_ALLOWED=NO
```

The scheme includes `LiquidGlassEffectTests` and `LiquidGlassDemoUITests`.
UI tests exercise live tint, corner, appearance, grouping and motion controls,
plus the original gallery's Like and Bookmark buttons. They retain screenshot
attachments for light/dark and standalone/grouped comparison. Passing UI actions
and assertions is not by itself proof of optical fidelity: review the attached
images and moving-background behavior on the target runtime.

---

## File Structure | 文件结构

```
Example/
├── project.yml          # XcodeGen config | XcodeGen 配置
├── generate.sh          # Generate script | 生成脚本
├── build_ipa.sh         # Build IPA script | 构建 IPA 脚本
├── LiquidGlassDemo/
│   ├── LiquidGlassDemoApp.swift
│   ├── ContentView.swift
│   ├── OpticsValidationView.swift
│   └── Assets.xcassets/
└── LiquidGlassDemoUITests/
    └── LiquidGlassDemoUITests.swift
```

---

## Screenshots | 截图

Run the app to see the effects.  
运行应用查看效果。

The optical UI tests keep their screenshots in the Xcode test result bundle.
光学对照 UI 测试将截图保存在 Xcode 测试结果包中。
