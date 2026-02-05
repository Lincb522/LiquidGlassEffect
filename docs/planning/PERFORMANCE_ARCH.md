# 高性能架构设计方案 (Performance Architecture)

本文档详细描述了 `LiquidGlassEffect` v2.0 中**纹理池 (Texture Pool)** 和 **共享背景上下文 (Shared Context)** 的技术实现方案。

## 1. 全局纹理池 (Texture Pool)

### 1.1 背景与动机
在 iOS 中，`MTLTexture` 是显存占用的主要来源。当前的实现中，每个 `LiquidGlassView` 持有两个全尺寸的纹理（双缓冲）。如果一个页面有 10 个玻璃卡片，就会创建 20 张纹理。
对于相同尺寸的组件（如 List 中的 Cell），这些纹理是可以被复用的。

### 1.2 设计思路
建立一个全局单例 `LiquidGlassTexturePool`，负责管理 `MTLTexture` 的生命周期。

#### 核心数据结构
```swift
class LiquidGlassTexturePool {
    static let shared = LiquidGlassTexturePool()
    
    // 纹理缓存池：Key 为纹理描述符的 Hash，Value 为空闲纹理数组
    private var pool: [TextureDescriptorKey: [MTLTexture]] = [:]
    
    // 正在使用的纹理引用（用于调试和内存统计）
    private var activeTextures: NSHashTable<MTLTexture> = .weakObjects()
}
```

#### 纹理获取流程 (Checkout)
1.  `LiquidGlassView` 请求纹理，提供尺寸和像素格式。
2.  Pool 根据描述符生成 Key。
3.  查找 `pool[key]` 是否有可用纹理。
    -   **Hit**: 移除并返回该纹理。
    -   **Miss**: 创建一个新的 `MTLTexture` 并返回。

#### 纹理归还流程 (Checkin)
1.  `LiquidGlassView` 释放纹理（如 `deinit` 或尺寸变更）。
2.  纹理被归还给 Pool。
3.  Pool 将纹理放入 `pool[key]` 数组中，供下次使用。

#### 自动清理策略 (Purge)
-   **内存警告**: 清空所有 `pool` 中的闲置纹理。
-   **后台进入**: 释放所有纹理（如果配置为省电模式）。
-   **定时清理**: 每隔 30秒 检查一次，释放超过一定时间未被使用的纹理。

## 2. 共享背景上下文 (Shared Background Context)

### 2.1 背景与动机
`drawHierarchy` (CPU Snapshot) 是极其昂贵的操作。如果 4 个 TabBarItem 紧挨着，它们其实都在同一个背景区域上。目前它们各自截取了一小块，导致 CPU 绘制了 4 次。

### 2.2 设计思路：LiquidGlassGroup

引入 `LiquidGlassGroup` 作为父容器，负责统一捕获背景，并将其分发给子组件。

```swift
struct LiquidGlassGroup<Content: View>: View {
    // 内部创建一个 Coordinator，负责背景捕获
    @StateObject private var coordinator = LiquidGlassGroupCoordinator()
    
    var body: some View {
        content
            .environmentObject(coordinator) // 将 Coordinator 传递给子组件
            .background(
                // 仅在 Group 层级进行一次背景捕获
                BackdropView(coordinator: coordinator)
            )
    }
}
```

#### 坐标映射 (UV Mapping)
子组件不再持有自己的背景纹理，而是持有**父容器纹理的引用**以及**自身的相对坐标 (Relative Frame)**。

在 Shader 中：
1.  传入父容器的大纹理。
2.  传入子组件在父容器中的归一化坐标 `(u_offset, v_offset, u_scale, v_scale)`。
3.  Fragment Shader 采样时，根据这些参数重新计算 UV：
    ```metal
    float2 parentUV = input.uv * scale + offset;
    half4 color = parentTexture.sample(s, parentUV);
    ```

### 2.3 预期收益
| 场景 | 优化前 CPU 耗时 | 优化后 CPU 耗时 | 收益 |
| :--- | :--- | :--- | :--- |
| TabBar (4 Items) | ~16ms (4x draw) | ~4ms (1x draw) | **400%** |
| List (10 Cells) | ~40ms (10x draw) | ~4ms (1x draw) | **1000%** |

## 3. 静态快照机制 (Static Snapshotting)

### 3.1 状态机设计
`LiquidGlassEngine` 将维护每个 View 的活跃状态：

-   **Active**: 正常渲染 (60fps)。
-   **Idle**: 只有微弱的光效动画 (30fps)。
-   **Frozen**: 完全静止，停止渲染 (0fps)。

### 3.2 触发条件
-   **进入 Frozen**: 连续 N 帧无触摸事件 && 陀螺仪数据无变化 && ScrollView 停止滚动。
-   **退出 Frozen**: 任意触摸事件 || 陀螺仪变化 || 属性更新。

### 3.3 实现细节
当进入 Frozen 状态时：
1.  执行最后一次 Metal 渲染。
2.  将 `CAMetalDrawable` 的纹理内容拷贝到一个静态的 `CGImage` 或保留最后一帧。
3.  暂停 `MTKView` 的 `isPaused = true`。
4.  展示静态图片覆盖在 View 上（或者直接利用 `MTKView` 的保留帧特性）。

---
*Created by Architect Agent for LiquidGlassEffect Team*
