# 光学架构与验证

版本：**3.0.0，含边缘专项 v2。**2026-10-14，Xcode 26.4 / iPhone 16 / iOS 18.4 Simulator 最终完整执行 **26/26 通过，0 失败、0 跳过**（23 项渲染/资源/阴影测试 + 3 项 UI 测试）。已检查最终画廊、浅色、深色分组截图；新增 6 项包含在本次结果中。

**第一轮历史记录（2026-10-14，边缘 v2 之前）：**Xcode 26.4 / iPhone 16 / iOS 18.4 Simulator 从干净 DerivedData 执行 20/20 通过，0 失败、0 跳过；其中 17 项 Metal/MPS/资源测试、3 项 UI 测试，当时的浅/深色与独立/分组截图也已检查。**这些历史证据不覆盖本轮边缘 v2、外投影/裁剪调整和新增 6 项测试。**最低部署版本仍为 iOS 15，不代表其他版本或真机已验收。

## 目标与非目标

目标是在已有 SwiftUI 组件接口之下，提供更明确的材质厚度、边缘折射、柔化主体和受控高光；先修正背景采样和资源生命周期，再调整外观。

这是一种屏幕空间近似，不是 Apple Liquid Glass 私有实现，也不是准确的三维光学仿真。Regular/Lens 的名称描述本库预设，不等同于系统材质。旧的预设数值与截图不是新版外观合同。

## 数据流

```text
玻璃后方 compositor 内容
  -> BackdropView / CABackdropLayer
  -> drawHierarchy / Core Graphics
  -> CVPixelBufferPool 租借的一帧
  -> CVMetalTexture + MTLTexture + window captureRect
       |                       |
       | raw/sharp             +-> MPSImageGaussianBlur -> soft
       +-------------------------------+-------------------+
                                       |
                             Metal SDF + 折射 + 高光
                                       |
                         MTKView drawable + layer 外投影
```

### 1. 背景来源必须真实

独立捕获将 backdrop 插入玻璃视图下方；分组将 backdrop 放在整个 group 内容下方，避免反复截入玻璃和标签导致反馈。分组中的所有表面共享原始背景帧，不是逐子视图重复捕获。

捕获仍采用**私有 `CABackdropLayer`**。私有类缺失时会明确失败，捕获错误会输出诊断；没有换成渐变或静态毛玻璃来冒充效果的路径。捕获失败时不发布新帧：已有帧可能暂时保留，首次失败则没有可采样内容。检查画面冻结时必须同时查看捕获日志。

### 2. 坐标约定

- UIKit/Core Graphics 输入内容、CV texture 行和 shader UV 均以左上角为基准。
- `CapturedBackdrop.captureRect` 使用 window-space point，而不是子视图的局部 `frame`。
- `LiquidGlassSampling.mapping` 将视图的 window rect 转成捕获图上的 `uvOffset` 和 `uvScale`；独立/分组调用同一函数。
- 独立捕获扩大的实际矩形与 texture coefficient 一起记录，避免“捕获更多背景”被误作“把整张背景缩进控件”。
- 分组采用 host/children 的联合范围并留出边缘采样余量；每个子视图仍读取自己的区域。
- `thumb(magnification:)` 明确在控件中心采样较小区域，从而放大。不要用 overscan 当作隐式缩放。

SDF、圆角半径、厚度和采样位移在 **point** 中计算。屏幕 scale 只负责像素转换、抗锯齿和纹理密度。方向高光使用归一化法线，避免相同参数在大面板和小按钮上产生由高度归一化导致的亮度差。

### 3. 两种背景频率

`raw` 纹理保留原始细节。`soft` 纹理由 `MPSImageGaussianBlur` 生成，blur radius 从 point 转换为对应纹理 pixel sigma；radius 为零时使用原图。

模糊写入独立目标纹理，不修改原图。两条输入使 shader 能在边缘保持清晰折射，在内部渐进增加散射，而不是先把整个背景糊掉再拉伸。

独立表面的模糊与采样提交到同一 command buffer，并限制 scratch output 的 in-flight 工作。分组按每帧和 sigma 缓存独立输出，首个消费者编码 blur，后续消费者使用同一有序 command queue；commit 后才发布缓存。entry 弱持有 producer，检查失败状态并按身份清理。不同 sigma 仍分别计算，输出不跨帧覆写。

### 4. 边缘 v2：分开控制反射、折射与散射

圆角 SDF 给出连续的边缘深度。各层使用不同的空间尺度，而不是用厚度同时生成宽白边、折射坡和阴影环：

| 层 | 当前实现 | 要验证的行为 |
|---|---|---|
| 高光唇 | 以约 0.20 point 深度为中心的紧致 Gaussian；默认参数约 0.6 point FWHM | 深灰底 0.5 point 内侧能看到亮边，而 2 point 起没有宽泛白尾 |
| Fresnel | 自身紧致 Gaussian 空间权重，和方向高光共享反射预算 | 不再独立执行第二次白色混合 |
| 内暗谷 | 独立以约 1 point 深度为中心的 Gaussian，受光照方向与 glare 控制 | 白底表现为轻微内暗线，约 2 point 后恢复主体，不形成浮雕宽边 |
| 折射肩部 | `thickness × 0.45` 限制到通常 2–5 point；极小表面额外受半尺寸约束 | 局部场景位移集中在边缘附近；通过 `smoothstep(0, 2, thickness)` 使薄层位移连续趋零 |
| 主体散射 | 与折射 shoulder 分开的 optical depth，保留 raw/soft 逐渐混合 | 收窄高光与折射区域不会让清晰边缘直接被整块模糊替代 |

Gaussian 宽度纳入当前抗锯齿像素 footprint，点单位定义不等于强行使用相同数量像素；需要以同一 point 区间的 2x/3x 剖面验证。表中的尺度描述默认风格和新测试参数，不是任意自定义 uniforms 的固定输出保证。

shader 在线性颜色空间混合清晰/柔化背景与材质 tint，独立施加轻内暗谷，然后把 Fresnel 与 directional glare **合并为一次有上限的反射预算**，只做一次亮色混合。中性光学参数仍要求原色透传，不应残留固定描边。折射位移继续约束三角函数域；色散只是小幅波长差，不是彩虹边框。

最后转换回 sRGB，并在抗锯齿边界输出 premultiplied alpha。材质内部不是靠统一降低 alpha 伪造透明，而是显示实际被采样的背景。上述默认参数已通过本轮 GPU/UI 回归，并检查实际运行截图；其他自定义参数不由这些测试自动保证。

### 5. 捕获帧的所有权

一帧持有 `CVPixelBuffer`、`CVMetalTexture`、`MTLTexture` 和捕获矩形。仍有消费者持有时，新的 capture 不会覆盖它的 pixel buffer；提交给 GPU 的帧由 completion closure 保留到 command 结束。改变 buffer 大小或释放 bridge 当前 pool，不应使已持有的帧失效。

主渲染链路使用这个带生命周期的帧，不把 Core Video 纹理交给普通 `LiquidGlassTexturePool` 回收。兼容 API `ZeroCopyBridge.render(actions:)` 返回裸 `MTLTexture`，因此复制到独立 Metal allocation 后才释放 capture lease；不要把该兼容调用描述为零复制。

### 6. SwiftUI 更新

`LiquidGlassMetalView.updateUIView` 传入最新 config。`LiquidGlassView.updateConfiguration` 更新 uniforms；捕获系数变化时重新建立 capture，阴影开关或形状相关配置变化时更新自身 layer 外投影。圆角通过更新方法同步进入 shader 与 shadow path，同尺寸下改变圆角也应立即更新投影，不等待未来一次尺寸布局。

Optics 页故意不以 `.id(...)` 重建玻璃：Blue tint、Tight corners 等按钮用于检查真实配置传播，而不是靠销毁/重建掩盖更新问题。

### 7. 外投影与内容裁剪

玻璃主链路不再创建覆盖表面的 `ShadowView` 环影子视图。公开 `ShadowView` 类型暂保留以免改变已有 API，但不参与当前表面的投影；`shadowOverlay` 参数继续保留，其作用为开关 **LiquidGlassView 自身 layer 的外投影**。

默认圆角矩形使用与 bounds 和受限半径一致的 `UIBezierPath`，并在布局、同尺寸圆角调整和阴影开关变化时同步。存在自定义 rectangles、smooth union 或非圆曲率时，取消整块 bounds 的固定 path，让 Core Animation 使用实际 Metal alpha 轮廓投影，避免未覆盖区域也出现矩形投影。

`LiquidGlassContainer` 先对前景 content 应用裁剪，再添加玻璃 background：**裁内容，不裁玻璃。**玻璃 SDF 是自身抗锯齿轮廓；外层再次裁整个表面会削掉细高光唇和外投影。调用方在更外层使用 `.clipShape(...)` 或 `.clipped()` 仍会裁到它们，集成时应检查 modifier 顺序。

新增阴影测试检查路径/属性更新与状态恢复，不代替实际画面的阴影观感验收。

## 预设迁移

| 预设 | 当前意图 | 迁移注意 |
|---|---|---|
| `.regular` | 柔化主体、清晰折射边缘 | 默认 blur 由 10 降至 5 point；厚度、折射和高光重新校准 |
| `.lens` | 零额外模糊的清晰透镜 | 新的边缘模型与折射率会改变变形量 |
| `.subtle` | 较弱的折射/高光 | 不是关闭玻璃，也不是普通透明填充 |
| `.thumb()` | 小型控件与显式放大 | 放大为中心采样，尺寸和不同屏幕 scale 需检查 |
| `.telegram` | 更强主体散射 | 仍使用本库渲染，不代表第三方 App 的像素复刻 |

公开 SwiftUI modifier 和组件构造方式保留。自定义 uniforms 的数值语义随光学模型改变，必须复查；不声明所有低层类型或私有实现的 ABI 兼容。

## 可复现验证

### 运行入口

仓库根目录可直接运行 `./scripts/test-ios18.sh`；支持 `SIMULATOR_UDID` 与 `ARTIFACT_DIR`。脚本严格选择已存在的 iOS 18.x 设备，保存日志和 xcresult，不自动改用其他系统。边缘 v2 的完整 26 项结果见本文开头；后续源码变更仍需完整复测，历史结果不自动继承。

在仓库 `Example` 目录运行 XcodeGen，然后使用实际安装的 iOS 18 simulator UDID：

```bash
xcodegen generate
xcodebuild test \
  -project LiquidGlassDemo.xcodeproj \
  -scheme LiquidGlassDemo \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -resultBundlePath /tmp/LiquidGlassOptics-iOS18.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

结果路径必须尚未存在。记录 Xcode 版本、OS/runtime、设备 UDID、源码 revision、测试结果包和完整错误信息；不要仅保存一张“看起来正常”的截图。

### 自动测试覆盖

- Swift/Metal uniform 内存布局。
- 独立 overscan、中心放大及分组 window-space UV 映射。
- 在真实 Metal texture 上验证中性色和左上角方向。
- 原始边缘/柔化主体使用不同输入纹理。
- 不同控件高度的方向高光、多个 SDF 形状间透明间隙。
- MPS out-of-place 模糊、原始纹理不变以及重新使用输入纹理时的刷新。
- 连续捕获、尺寸变化和释放 pool 之后，已持有帧和兼容裸纹理的生命周期。
- UI 启动、六个实时开关、原画廊按钮、光学对照入口与返回。

**边缘 v2 新增 6 项回归（已纳入最终 26 项执行）：**

1. `testCompactHighlightLipDoesNotLeaveAWhiteTailOnDarkBackdrop`：真实 GPU 渲染 RGB 64 深灰底，3x 下 0.5 point 内侧高光至少增加 15 级；从 2.167 point 起逐行回到原色 ±3，防止宽泛白尾。
2. `testWhiteBackdropHasAGentleInnerLineWithoutDimmingTheBody`：白底背光边约 0.833 / 1.167 point 两行平均形成轻内暗线，2 point 后与中心保持白底。
3. `testCompactEdgeProfilesRemainPointSizedAtTwoAndThreeTimesScale`：对相同 point 区间进行多像素覆盖加权比较，允许窄唇采样误差，但内部恢复容差更严。
4. `testRefractionConvergesContinuouslyToZeroForThinLayers`：实际 GPU 读取渐变源，厚度 0.0001 / 0.01 / 0.1 接近零位移，2 point 厚度仍产生可测折射，防止肩宽下限导致零点跳变。
5. `testExternalShadowTracksSizeAndSameSizeRadiusUpdates`：检查外投影几何、尺寸、同尺寸圆角、开关更新，以及没有 `ShadowView` 表面叠层。
6. `testCustomShapesUseMetalAlphaShadowAndRestoreDefaultPath`：检查自定义 rectangles、非圆曲率、smooth union 使用真实 alpha 轮廓，以及恢复默认形状后重建精确 path。

前四项使用实际 Metal 渲染与 readback；后两项验证 UIKit/Metal 视图的 layer 状态和路径。原有中性透传、双纹理与其他测试未因 v2 被弱化。**最终计数为 26/26，测试通过不等于视觉与真机性能验收；**实际执行数量、结果和运行限制以本轮 `.xcresult` 为准。

### 视觉与动态验收清单

1. 用 `--optics` 启动，先保持背景静止。检查 Regular/Lens 背后网格上下方向、字号和位置没有整体翻转、错位或无意缩小。
2. 对比圆形、胶囊、宽面板。边缘应体现局部位移与材质厚度，宽面板不应因高度变化而整块发白。边缘 v2 要特别检查紧致亮唇、独立轻内暗谷，以及约 2 point 后不存在宽白尾；浅色背景同时检查外投影，而不是表面环影。
3. 切换 Blue tint 和 Tight corners；原表面应实时变化，外投影路径也要随同尺寸圆角调整。分别检查浅色/深色背景的可读性、细高光唇及玻璃外部阴影没有被整体裁剪。
4. 切换 Grouped。空间对应关系应稳定，不应采样到邻居卡片内容；将状态分别保存为截图，不要求独立/分组模糊边界逐像素相等。
5. 开启 Motion，持续观察背景移动穿过所有玻璃。控件自身不动时，玻璃内部仍需刷新；确认没有冻结、反馈重影或闪烁。
6. 关闭 Glass，获得未覆盖的背景参考；重新开启，再比较实际变形。不能只凭边框/高光存在判断背景捕获成功。
7. 进入后台再返回、改变页面、滚动和重复切换分组，检查捕获恢复和资源释放。
8. 查看原五页画廊，实际点击 Like、Bookmark、输入框和滑块，确认玻璃不拦截交互。

UI 测试附带的截图辅助人工评审；测试点击通过不证明光学质量。模拟器证据也不代表真机功耗或帧率。

## 尚需独立验证的限制

- 私有 API 的 OS 兼容与分发可接受性；没有 App Store 接受承诺。
- iOS 15–17、后续系统与不同 GPU 真机；仅 deployment target 不构成通过证据。
- 视频/Metal 背景、受保护内容、复杂 transform、多窗口、嵌套分组的捕获和坐标。
- Reduce Transparency、Reduce Motion、高对比度、Dynamic Type 及完整 VoiceOver 流程。
- 能耗、显存峰值和延迟。分组是一次共享 capture，同帧相同 sigma 共享 blur；不同 sigma 的模糊及各表面绘制仍消耗 GPU。当前分组请求 30 fps，不是按背景静止自动暂停；`.static` 只是较低帧率模式。

没有对 CPU 百分比、零 GPU 占用、固定 1–2 帧延迟作测量结论。旧普通纹理池的分桶与数量限制也不等于 LRU。

## 许可与来源

保留项目既有的 [LiquidGlassKit](https://github.com/DnV1eX/LiquidGlassKit) 致谢。上游 README 声明 MIT，但本次取得的上游/checkout 缺少根目录 `LICENSE` 正文；本文不补造许可证或保证再分发条件已经齐全。
