//
//  ContentView.swift
//  LiquidGlassDemo
//
//  展示 LiquidGlassEffect 库的所有组件
//

import SwiftUI
import LiquidGlassEffect

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 背景
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // 分页展示，减少同时渲染的组件数量
                ButtonDemoPage()
                    .tag(0)
                
                CardDemoPage()
                    .tag(1)
                
                ControlsDemoPage()
                    .tag(2)
                
                ProgressDemoPage()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 底部 TabBar - iOS 26 风格
            VStack {
                Spacer()
                
                LiquidGlassTabBar(
                    selectedIndex: $selectedTab,
                    items: [
                        .init(id: 0, icon: "square.grid.2x2", activeIcon: "square.grid.2x2.fill"),
                        .init(id: 1, icon: "rectangle.stack", activeIcon: "rectangle.stack.fill"),
                        .init(id: 2, icon: "slider.horizontal.3"),
                        .init(id: 3, icon: "chart.bar", activeIcon: "chart.bar.fill")
                    ]
                )
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Page 1: Buttons

struct ButtonDemoPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 标题
            VStack(spacing: 12) {
                Text("Liquid Glass")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Button 按钮组件")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            // 文字按钮
            HStack(spacing: 12) {
                LiquidGlassButton(action: {}) {
                    Label("主要按钮", systemImage: "star.fill")
                        .foregroundStyle(.white)
                }
                
                LiquidGlassButton(cornerRadius: 12, action: {}) {
                    Text("次要")
                        .foregroundStyle(.white)
                }
            }
            
            // 图标按钮
            HStack(spacing: 16) {
                LiquidGlassIconButton(icon: "heart.fill", size: 50, action: {})
                LiquidGlassIconButton(icon: "bookmark.fill", size: 50, action: {})
                LiquidGlassIconButton(icon: "square.and.arrow.up", size: 50, action: {})
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Page 2: Cards

struct CardDemoPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Card 卡片组件")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            // 列表卡片
            LiquidGlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("液态玻璃卡片")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("支持任意内容")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // 通知卡片
            LiquidGlassNotification(
                icon: "bell.fill",
                title: "系统通知",
                message: "iOS 26 液态玻璃效果",
                iconColor: .orange
            )
            
            // 标签
            HStack(spacing: 8) {
                LiquidGlassTag("iOS 26", icon: "sparkles")
                LiquidGlassTag("SwiftUI")
                LiquidGlassTag("Metal", icon: "cube.fill")
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Page 3: Controls

struct ControlsDemoPage: View {
    @State private var brightness: Double = 0.7
    @State private var searchText = ""
    @State private var darkMode = true
    @State private var captureFPS: Double = 30.0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Controls 控件")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            // 性能控制演示
            VStack(alignment: .leading, spacing: 10) {
                Text("背景捕获帧率: \(Int(captureFPS)) FPS")
                    .font(.caption)
                    .foregroundStyle(.white)
                
                Slider(value: $captureFPS, in: 1...60, step: 1)
                    .tint(.white)
                
                Text("共享背景优化 (Shared Context)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 使用 LiquidGlassGroup 包裹多个组件，验证共享背景
            // 理论上，这 3 个组件应该只触发一次 drawHierarchy，而不是 3 次
            LiquidGlassGroup {
                VStack(spacing: 24) {
                    // 滑块
                    HStack(spacing: 16) {
                        LiquidGlassSlider(
                            value: $brightness,
                            icon: "sun.max.fill",
                            iconColor: .yellow,
                            backgroundCaptureFrameRate: captureFPS
                        )
                        Spacer()
                    }
                    
                    // 输入框
                    LiquidGlassTextField(
                        "搜索...",
                        text: $searchText,
                        icon: "magnifyingglass",
                        backgroundCaptureFrameRate: captureFPS
                    )
                    
                    // 开关
                    LiquidGlassCard(backgroundCaptureFrameRate: captureFPS) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.purple)
                            Text("深色模式")
                                .foregroundStyle(.white)
                            Spacer()
                            LiquidGlassToggle(isOn: $darkMode, backgroundCaptureFrameRate: captureFPS)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Page 4: Progress

struct ProgressDemoPage: View {
    @State private var linearProgress: Double = 0.65
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Progress 进度")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            // 线性进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("下载进度")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(linearProgress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                LiquidGlassProgress(value: linearProgress, tintColor: .cyan)
            }
            
            // 圆形进度
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    LiquidGlassCircularProgress(value: 0.75, tintColor: .green)
                    Text("存储")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    LiquidGlassCircularProgress(value: 0.45, tintColor: .orange, size: 60)
                    Text("电量")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ContentView()
}
