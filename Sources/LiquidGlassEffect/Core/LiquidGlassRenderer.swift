//
//  LiquidGlassRenderer.swift
//  LiquidGlassEffect
//
//  Metal 渲染器（单例）
//

import Metal

/// Metal 渲染器单例
public final class LiquidGlassRenderer {
    
    public static let shared: LiquidGlassRenderer? = LiquidGlassRenderer()
    
    public let device: MTLDevice
    public let pipelineState: MTLRenderPipelineState
    
    private init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[LiquidGlassEffect] Metal 不支持")
            return nil
        }
        self.device = device
        
        guard let library = Self.loadShaderLibrary(device: device) else {
            print("[LiquidGlassEffect] 无法加载 shader")
            return nil
        }
        
        guard let vertexFunction = library.makeFunction(name: "fullscreenQuad"),
              let fragmentFunction = library.makeFunction(name: "liquidGlassEffect") else {
            print("[LiquidGlassEffect] 找不到 shader 函数")
            return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("[LiquidGlassEffect] Shader 加载成功")
        } catch {
            print("[LiquidGlassEffect] Pipeline 创建失败: \(error)")
            return nil
        }
    }
    
    private static func loadShaderLibrary(device: MTLDevice) -> MTLLibrary? {
        do {
            return try device.makeDefaultLibrary(bundle: .module)
        } catch {
            print("[LiquidGlassEffect] Shader 加载失败: \(error)")
            return nil
        }
    }
}
