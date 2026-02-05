//
//  LiquidGlassFloatingBar.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃悬浮栏和 TabBar
//

import SwiftUI

// MARK: - Floating Bar

/// 液态玻璃悬浮栏
///
/// 适用于底部工具栏、播放控制栏等场景。
public struct LiquidGlassFloatingBar<Content: View>: View {
    
    private let content: Content
    private let cornerRadius: CGFloat
    private let config: LiquidGlassConfig
    
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

// MARK: - Tab Bar

/// iOS 26 风格液态玻璃 TabBar
///
/// 选中项有独立的液态玻璃气泡，切换时气泡平滑流动。
public struct LiquidGlassTabBar: View {
    
    // MARK: - Types
    
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
    
    // MARK: - Properties
    
    @Binding var selectedIndex: Int
    let items: [TabBarItem]
    var config: LiquidGlassConfig
    
    private let itemWidth: CGFloat = 52
    private let itemHeight: CGFloat = 36
    private let padding: CGFloat = 6
    
    @Namespace private var animationNamespace
    
    // MARK: - Init
    
    public init(
        selectedIndex: Binding<Int>,
        items: [TabBarItem],
        config: LiquidGlassConfig = .thumb()
    ) {
        self._selectedIndex = selectedIndex
        self.items = items
        self.config = config
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // 背景玻璃层
            LiquidGlassContainer(config: .regular, cornerRadius: (itemHeight + padding * 2) / 2) {
                Color.clear
                    .frame(
                        width: CGFloat(items.count) * itemWidth + padding * 2,
                        height: itemHeight + padding * 2
                    )
            }
            
            // 选中气泡层
            HStack(spacing: 0) {
                ForEach(items) { item in
                    if selectedIndex == item.id {
                        LiquidGlassContainer(config: config, cornerRadius: itemHeight / 2) {
                            Color.clear
                        }
                        .frame(width: itemWidth, height: itemHeight)
                        .matchedGeometryEffect(id: "activeTab", in: animationNamespace)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    } else {
                        Spacer().frame(width: itemWidth, height: itemHeight)
                    }
                }
            }
            .padding(padding)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedIndex)
            
            // 内容层
            HStack(spacing: 0) {
                ForEach(items) { item in
                    TabItemButton(
                        item: item,
                        isSelected: selectedIndex == item.id,
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

// MARK: - Tab Item Button

private struct TabItemButton: View {
    let item: LiquidGlassTabBar.TabBarItem
    let isSelected: Bool
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            Image(systemName: isSelected ? (item.activeIcon ?? item.icon) : item.icon)
                .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .scaleEffect(isPressed ? 0.8 : (isSelected ? 1.05 : 1.0))
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                .frame(width: itemWidth, height: itemHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Labeled Tab Bar

/// 带文字标签的 TabBar
public struct LiquidGlassLabeledTabBar: View {
    
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
    
    @Binding var selectedIndex: Int
    let items: [LabeledTabItem]
    var config: LiquidGlassConfig
    
    @Namespace private var animationNamespace
    
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
                    LabeledTabItemButton(
                        item: item,
                        isSelected: selectedIndex == item.id,
                        config: config,
                        animationNamespace: animationNamespace
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

private struct LabeledTabItemButton: View {
    let item: LiquidGlassLabeledTabBar.LabeledTabItem
    let isSelected: Bool
    let config: LiquidGlassConfig
    let animationNamespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    .matchedGeometryEffect(id: "activeLabeledTab", in: animationNamespace)
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

// MARK: - Pill Tab Bar

/// 药丸形状 TabBar - 更紧凑的设计
public struct LiquidGlassPillTabBar: View {
    
    public struct PillTabItem: Identifiable {
        public let id: Int
        public let icon: String
        
        public init(id: Int, icon: String) {
            self.id = id
            self.icon = icon
        }
    }
    
    @Binding var selectedIndex: Int
    let items: [PillTabItem]
    var config: LiquidGlassConfig
    
    @Namespace private var animationNamespace
    
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
                    PillTabItemButton(
                        item: item,
                        isSelected: selectedIndex == item.id,
                        config: config,
                        animationNamespace: animationNamespace
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

private struct PillTabItemButton: View {
    let item: LiquidGlassPillTabBar.PillTabItem
    let isSelected: Bool
    let config: LiquidGlassConfig
    let animationNamespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
                    .matchedGeometryEffect(id: "activePillTab", in: animationNamespace)
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
