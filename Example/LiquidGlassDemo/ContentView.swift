//
//  ContentView.swift
//  LiquidGlassDemo
//
//  LiquidGlassEffect v2.1.0 组件展示
//

import SwiftUI
import LiquidGlassEffect

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4),
                    Color(red: 0.3, green: 0.15, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 装饰圆形
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
                
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: geo.size.width / 2, y: 100)
            }
            
            // 内容
            TabView(selection: $selectedTab) {
                ButtonsPage()
                    .tag(0)
                
                CardsPage()
                    .tag(1)
                
                FormsPage()
                    .tag(2)
                
                ProgressPage()
                    .tag(3)
                
                NavigationPage()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 底部导航
            VStack {
                Spacer()
                
                LiquidGlassPillTabBar(
                    selectedIndex: $selectedTab,
                    items: [
                        .init(id: 0, icon: "hand.tap"),
                        .init(id: 1, icon: "rectangle.stack"),
                        .init(id: 2, icon: "slider.horizontal.3"),
                        .init(id: 3, icon: "chart.bar"),
                        .init(id: 4, icon: "rectangle.3.group")
                    ]
                )
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Page 1: Buttons

struct ButtonsPage: View {
    @State private var likeCount = 0
    @State private var isBookmarked = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 标题
                PageHeader(
                    title: "Buttons",
                    subtitle: "按钮组件"
                )
                
                // 通用按钮
                SectionHeader("LiquidGlassButton")
                
                VStack(spacing: 16) {
                    LiquidGlassButton(action: { likeCount += 1 }) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                            Text("点赞 \(likeCount)")
                        }
                        .foregroundStyle(.white)
                    }
                    
                    HStack(spacing: 12) {
                        LiquidGlassButton(cornerRadius: 12, action: {}) {
                            Text("确定")
                                .foregroundStyle(.white)
                        }
                        
                        LiquidGlassButton(cornerRadius: 12, config: .subtle, action: {}) {
                            Text("取消")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                
                // 文本按钮
                SectionHeader("LiquidGlassTextButton")
                
                HStack(spacing: 12) {
                    LiquidGlassTextButton("保存", action: {})
                    LiquidGlassTextButton("分享", action: {})
                }
                
                // 图标按钮
                SectionHeader("LiquidGlassIconButton")
                
                HStack(spacing: 20) {
                    LiquidGlassIconButton(
                        icon: "heart.fill",
                        size: 56,
                        iconColor: .pink,
                        action: {}
                    )
                    
                    LiquidGlassIconButton(
                        icon: isBookmarked ? "bookmark.fill" : "bookmark",
                        size: 56,
                        isActive: isBookmarked,
                        action: { isBookmarked.toggle() }
                    )
                    
                    LiquidGlassIconButton(
                        icon: "square.and.arrow.up",
                        size: 56,
                        action: {}
                    )
                    
                    LiquidGlassIconButton(
                        icon: "ellipsis",
                        size: 56,
                        action: {}
                    )
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Page 2: Cards

struct CardsPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                PageHeader(
                    title: "Cards",
                    subtitle: "卡片与容器"
                )
                
                // 卡片
                SectionHeader("LiquidGlassCard")
                
                LiquidGlassCard {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("正在播放")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Liquid Glass - Demo")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                    }
                }
                
                // 通知
                SectionHeader("LiquidGlassNotification")
                
                LiquidGlassNotification(
                    icon: "bell.badge.fill",
                    title: "新消息",
                    message: "你有 3 条未读消息",
                    iconColor: .orange
                )
                
                LiquidGlassNotification(
                    icon: "checkmark.circle.fill",
                    title: "下载完成",
                    message: "文件已保存到本地",
                    iconColor: .green
                )
                
                // Toast
                SectionHeader("LiquidGlassToast")
                
                HStack(spacing: 12) {
                    LiquidGlassToast("已复制", icon: "doc.on.doc")
                    LiquidGlassToast("已保存", icon: "checkmark")
                }
                
                // 标签
                SectionHeader("LiquidGlassTag & Badge")
                
                HStack(spacing: 8) {
                    LiquidGlassTag("iOS 26", icon: "sparkles")
                    LiquidGlassTag("SwiftUI")
                    LiquidGlassTag("Metal", icon: "cube.fill")
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("消息")
                            .foregroundStyle(.white)
                        LiquidGlassBadge(count: 5)
                    }
                    
                    HStack(spacing: 4) {
                        Text("通知")
                            .foregroundStyle(.white)
                        LiquidGlassBadge(count: 99)
                    }
                    
                    HStack(spacing: 4) {
                        Text("更新")
                            .foregroundStyle(.white)
                        LiquidGlassBadge(count: 128, maxCount: 99)
                    }
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Page 3: Forms

struct FormsPage: View {
    @State private var username = ""
    @State private var password = ""
    @State private var brightness: Double = 0.7
    @State private var volume: Double = 0.5
    @State private var darkMode = true
    @State private var notifications = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                PageHeader(
                    title: "Forms",
                    subtitle: "表单控件"
                )
                
                // 输入框
                SectionHeader("LiquidGlassTextField")
                
                VStack(spacing: 12) {
                    LiquidGlassTextField(
                        "用户名",
                        text: $username,
                        icon: "person"
                    )
                    
                    LiquidGlassSecureField(
                        "密码",
                        text: $password
                    )
                }
                
                // 滑块
                SectionHeader("LiquidGlassSlider")
                
                HStack(spacing: 20) {
                    LiquidGlassSlider(
                        value: $brightness,
                        icon: "sun.max.fill",
                        iconColor: .yellow,
                        height: 140
                    )
                    .frame(width: 60)
                    
                    LiquidGlassSlider(
                        value: $volume,
                        icon: "speaker.wave.2.fill",
                        iconColor: .white,
                        height: 140
                    )
                    .frame(width: 60)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("亮度: \(Int(brightness * 100))%")
                            .foregroundStyle(.white)
                        Text("音量: \(Int(volume * 100))%")
                            .foregroundStyle(.white)
                    }
                    .font(.subheadline)
                }
                
                // 开关
                SectionHeader("LiquidGlassToggle")
                
                VStack(spacing: 12) {
                    LiquidGlassLabeledToggle(
                        "深色模式",
                        subtitle: "使用深色主题",
                        isOn: $darkMode
                    )
                    
                    LiquidGlassLabeledToggle(
                        "推送通知",
                        subtitle: "接收消息提醒",
                        isOn: $notifications,
                        onColor: .orange
                    )
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Page 4: Progress

struct ProgressPage: View {
    @State private var downloadProgress: Double = 0.65
    @State private var uploadProgress: Double = 0.3
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                PageHeader(
                    title: "Progress",
                    subtitle: "进度指示器"
                )
                
                // 线性进度
                SectionHeader("LiquidGlassProgress")
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("下载进度")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(downloadProgress * 100))%")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .font(.subheadline)
                        
                        LiquidGlassProgress(value: downloadProgress, tintColor: .cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("上传进度")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(uploadProgress * 100))%")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .font(.subheadline)
                        
                        LiquidGlassProgress(value: uploadProgress, tintColor: .green, height: 12)
                    }
                }
                
                // 圆形进度
                SectionHeader("LiquidGlassCircularProgress")
                
                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        LiquidGlassCircularProgress(
                            value: 0.75,
                            tintColor: .green,
                            size: 70
                        )
                        Text("存储")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        LiquidGlassCircularProgress(
                            value: 0.45,
                            tintColor: .orange,
                            size: 70
                        )
                        Text("电量")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        LiquidGlassCircularProgress(
                            value: 0.9,
                            tintColor: .pink,
                            size: 70
                        )
                        Text("内存")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // 不确定进度
                SectionHeader("Indeterminate")
                
                HStack(spacing: 20) {
                    LiquidGlassIndeterminateProgress(tintColor: .cyan, size: 50)
                    
                    Text("加载中...")
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Spacer()
                }
                
                // 控制按钮
                HStack(spacing: 12) {
                    LiquidGlassTextButton("重置") {
                        withAnimation {
                            downloadProgress = 0
                            uploadProgress = 0
                        }
                    }
                    
                    LiquidGlassTextButton("模拟") {
                        withAnimation(.easeInOut(duration: 2)) {
                            downloadProgress = Double.random(in: 0.3...1.0)
                            uploadProgress = Double.random(in: 0.1...0.8)
                        }
                    }
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Page 5: Navigation

struct NavigationPage: View {
    @State private var tabIndex = 0
    @State private var labeledTabIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                PageHeader(
                    title: "Navigation",
                    subtitle: "导航组件"
                )
                
                // TabBar
                SectionHeader("LiquidGlassTabBar")
                
                LiquidGlassTabBar(
                    selectedIndex: $tabIndex,
                    items: [
                        .init(id: 0, icon: "house", activeIcon: "house.fill"),
                        .init(id: 1, icon: "magnifyingglass"),
                        .init(id: 2, icon: "heart", activeIcon: "heart.fill"),
                        .init(id: 3, icon: "person", activeIcon: "person.fill")
                    ]
                )
                
                // Labeled TabBar
                SectionHeader("LiquidGlassLabeledTabBar")
                
                LiquidGlassLabeledTabBar(
                    selectedIndex: $labeledTabIndex,
                    items: [
                        .init(id: 0, icon: "house", label: "首页"),
                        .init(id: 1, icon: "gear", label: "设置")
                    ]
                )
                
                // Pill TabBar
                SectionHeader("LiquidGlassPillTabBar")
                
                LiquidGlassPillTabBar(
                    selectedIndex: $tabIndex,
                    items: [
                        .init(id: 0, icon: "play.fill"),
                        .init(id: 1, icon: "pause.fill"),
                        .init(id: 2, icon: "forward.fill"),
                        .init(id: 3, icon: "backward.fill")
                    ]
                )
                
                // Floating Bar
                SectionHeader("LiquidGlassFloatingBar")
                
                LiquidGlassFloatingBar {
                    HStack(spacing: 24) {
                        Image(systemName: "backward.fill")
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Image(systemName: "forward.fill")
                    }
                    .foregroundStyle(.white)
                }
                
                // Container
                SectionHeader("LiquidGlassContainer")
                
                LiquidGlassContainer(cornerRadius: 16) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("这是一个基础容器")
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Helper Views

struct PageHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
}

struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
