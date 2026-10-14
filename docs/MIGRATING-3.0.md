# 从 2.x 升级到 3.0.0

3.0.0 保留主要 SwiftUI modifier、组件构造方式、产品/模块名与 iOS 15 最低部署声明，但不承诺旧行为和旧视觉参数不变。最低系统声明不等同于全系统运行验收。

## 更新依赖

```swift
.package(url: "https://github.com/Lincb522/LiquidGlassEffect.git", from: "3.0.0")
```

可用 `exact: "3.0.0"` 固定此版本。Xcode 选择 Up to Next Major Version，最低版本 3.0.0。保留 2.x 约束的项目不会自动跨主版本。

## 公开行为变化

1. **CGContext 坐标。**`ZeroCopyBridge.render(actions:)` 的回调 context 已执行 `translateBy(y: height)` 与 `scaleBy(y: -1)`，为 y 向下坐标。2.x 没有预先施加该转换。直接调用此底层 API 且自行翻转的代码应核对 CTM，移除重复翻转；需要原始 y 向上坐标的调用方应显式恢复其坐标约定。仅通过 SwiftUI 组件使用本库不需要修改绘图回调。
2. **按钮 action 时序。**玻璃按钮使用原生 SwiftUI Button，`pressStyle.pressDuration` 不再延迟 action。动画跟随手指按压状态；如业务需要等待，应在业务层明确处理，不依赖装饰动画控制业务时序。字段仍保留给既有 API 和独立 pressable modifier。
3. **光学参数与外观。**几何与光学位移使用 point 空间；regular、lens 等预设、厚度、折射、色散和边缘响应已重新校准。重新检查自定义 uniforms、亮/暗背景和文字可读性。regular 默认 blur 从 10 降至 5 point。
4. **阴影与裁切。**`shadowOverlay` 现在控制组件后方外投影，不再控制覆盖表面的环影。自定义容器不要再次裁切玻璃边缘与外投影；只裁前景内容。公开 ShadowView 类型保留。
5. **无效配置显式失败。**textureSizeCoefficient、textureScaleCoefficient、thumb magnification 须为正有限数；blurRadius 须为非负有限数。不要传 NaN、无穷或非正缩放。

`LiquidGlassEffectInfo.version` 为 `3.0.0`。包没有新增第三方依赖；Gaussian blur 继续使用系统 MPS。

## 验证与边界

运行 `./scripts/test-ios18.sh` 在已安装的 iOS 18 模拟器验证。此实现已有 iPhone 16 / iOS 18.4 的 26 项完整通过记录；真机、性能和其他 OS 分别验收。

背景捕获仍使用私有 CABackdropLayer，不承诺 App Store 审核接受。许可证正文缺失情况见 README；本次未补造授权文件。
