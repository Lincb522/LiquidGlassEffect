//
//  LiquidGlassFloatingBar.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃悬浮栏
//  Credits: https://github.com/DnV1eX/LiquidGlassKit
//

import SwiftUI

/// 液态玻璃悬浮栏
public struct LiquidGlassFloatingBar<Content: View>: View {
    
    let content: Content
    var cornerRadius: CGFloat
    var config: LiquidGlassConfig
    
    public init(
        cornerRadius: CGFloat = 28,
        config: LiquidGlassConfig = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.config = config
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .liquidGlass(config: config, cornerRadius: cornerRadius)
    }
}

// MARK: - iOS 26 风格 TabBar

/// iOS 26 风格液态玻璃 TabBar
/// 特点：选中项有独立的液态玻璃气泡，切换时气泡平滑流动
public struct LiquidGlassTabBar: View {
    
    @Binding var selectedIndex: Int
    let items: [TabBarItem]
    var config: LiquidGlassConfig
    
    /// 每个 tab 的宽度
    private let itemWidth: CGFloat = 52
    /// 每个 tab 的高度
    private let itemHeight: CGFloat = 36
    /// 内边距
    private let padding: CGFloat = 6
    
    public struct TabBarItem: Identifiable {
        public let id: Int
        public let icon: String
        public let activeIcon: String?
        
        public init(id: Int, icon: String, activeIcon: String? = nil) {
            self.id = id
            self.icon = icon
            self.activeIcon = activeIcon
        }
    }
    
    public init(
        selectedIndex: Binding<Int>,
        items: [TabBarItem],
        config: LiquidGlassConfig = .thumb()
    ) {
        self._selectedIndex = selectedIndex
        self.items = items
        self.config = config
    }
    
    public var body: some View {
        // 外层容器 - 使用液态玻璃效果
        ZStack {
            // 背景玻璃层
            LiquidGlassContainer(config: .regular, cornerRadius: (itemHeight + padding * 2) / 2) {
                Color.clear
                    .frame(
                        width: CGFloat(items.count) * itemWidth + padding * 2,
                        height: itemHeight + padding * 2
                    )
            }
            
            // 内容层
            HStack(spacing: 0) {
                ForEach(items) { item in
                    TabItemView(
                        item: item,
                        isSelected: selectedIndex == item.id,
                        config: config,
                        itemWidth: itemWidth,
                        itemHeight: itemHeight
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedIndex = item.id
                        }
                    }
                }
            }
            .padding(padding)
        }
    }
}

// MARK: - Tab Item View

private struct TabItemView: View {
    let item: LiquidGlassTabBar.TabBarItem
    let isSelected: Bool
    let config: LiquidGlassConfig
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                // 选中时的液态玻璃气泡
                if isSelected {
                    LiquidGlassContainer(config: config, cornerRadius: itemHeight / 2) {
                        Color.clear
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
                
                // 图标
                Image(systemName: isSelected ? (item.activeIcon ?? item.icon) : item.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .scaleEffect(isPressed ? 0.8 : (isSelected ? 1.05 : 1.0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .frame(width: itemWidth, height: itemHeight)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liquid Glass Container (内部使用)

/// 液态玻璃容器 - 用于包裹内容
public struct LiquidGlassContainer<Content: View>: View {
    let config: LiquidGlassConfig
    let cornerRadius: CGFloat
    let content: Content
    
    public init(
        config: LiquidGlassConfig = .regular,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .background {
                LiquidGlassMetalView(config: config, cornerRadius: cornerRadius)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - 带文字标签的 TabBar

/// iOS 26 风格带文字标签的 TabBar
public struct LiquidGlassLabeledTabBar: View {
    
    @Binding var selectedIndex: Int
    let items: [LabeledTabItem]
    var config: LiquidGlassConfig
    
    public struct LabeledTabItem: Identifiable {
        public let id: Int
        public let icon: String
        public let label: String
        
        public init(id: Int, icon: String, label: String) {
            self.id = id
            self.icon = icon
            self.label = label
        }
    }
    
    public init(
        selectedIndex: Binding<Int>,
        items: [LabeledTabItem],
        config: LiquidGlassConfig = .thumb()
    ) {
        self._selectedIndex = selectedIndex
        self.items = items
        self.config = config
    }
    
    public var body: some View {
        LiquidGlassContainer(config: .regular, cornerRadius: 28) {
            HStack(spacing: 4) {
                ForEach(items) { item in
                    LabeledTabItemView(
                        item: item,
                        isSelected: selectedIndex == item.id,
                        config: config
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedIndex = item.id
                        }
                    }
                }
            }
            .padding(6)
        }
    }
}

private struct LabeledTabItemView: View {
    let item: LiquidGlassLabeledTabBar.LabeledTabItem
    let isSelected: Bool
    let config: LiquidGlassConfig
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                if isSelected {
                    LiquidGlassContainer(config: config, cornerRadius: 20) {
                        Color.clear
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    if isSelected {
                        Text(item.label)
                            .font(.system(size: 14, weight: .medium))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, isSelected ? 16 : 12)
                .padding(.vertical, 10)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill TabBar (药丸形状)

/// iOS 26 风格药丸形状 TabBar - 更紧凑的设计
public struct LiquidGlassPillTabBar: View {
    
    @Binding var selectedIndex: Int
    let items: [PillTabItem]
    var config: LiquidGlassConfig
    
    public struct PillTabItem: Identifiable {
        public let id: Int
        public let icon: String
        
        public init(id: Int, icon: String) {
            self.id = id
            self.icon = icon
        }
    }
    
    public init(
        selectedIndex: Binding<Int>,
        items: [PillTabItem],
        config: LiquidGlassConfig = .thumb()
    ) {
        self._selectedIndex = selectedIndex
        self.items = items
        self.config = config
    }
    
    public var body: some View {
        LiquidGlassContainer(config: .regular, cornerRadius: 24) {
            HStack(spacing: 2) {
                ForEach(items) { item in
                    PillTabItemView(
                        item: item,
                        isSelected: selectedIndex == item.id,
                        config: config
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedIndex = item.id
                        }
                    }
                }
            }
            .padding(4)
        }
    }
}

private struct PillTabItemView: View {
    let item: LiquidGlassPillTabBar.PillTabItem
    let isSelected: Bool
    let config: LiquidGlassConfig
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                if isSelected {
                    LiquidGlassContainer(config: config, cornerRadius: 20) {
                        Color.clear
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                    .scaleEffect(isPressed ? 0.85 : 1.0)
            }
            .frame(width: 44, height: 40)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}
