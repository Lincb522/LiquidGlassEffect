import SwiftUI
import LiquidGlassEffect

/// A real rendered comparison scene. The exposed grid and letterforms are the
/// reference: their displacement and diffusion should change *inside* the glass.
struct OpticsValidationView: View {
    var onClose: () -> Void

    @State private var isDark = ProcessInfo.processInfo.arguments.contains("--optics-dark")
    @State private var isTinted = ProcessInfo.processInfo.arguments.contains("--optics-tint")
    @State private var isAngular = ProcessInfo.processInfo.arguments.contains("--optics-angular")
    @State private var isGrouped = ProcessInfo.processInfo.arguments.contains("--optics-grouped")
    @State private var isMoving = ProcessInfo.processInfo.arguments.contains("--optics-motion")
    @State private var showsGlass = !ProcessInfo.processInfo.arguments.contains("--optics-no-glass")
    @State private var motionOrigin = Date()

    private var ink: Color { isDark ? .white : Color(white: 0.08) }
    private var paper: Color { isDark ? Color(white: 0.065) : Color(white: 0.97) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                opticalStage
                    .frame(height: 350)
                    .accessibilityIdentifier("optics.stage")

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "viewfinder")
                    Text("Follow the grid through the edges. Regular diffuses; Lens keeps detail.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 12))
                .foregroundColor(ink.opacity(0.55))

                controls

                HStack {
                    Text(isGrouped ? "SHARED CAPTURE" : "INDEPENDENT CAPTURE")
                    Spacer()
                    Text("METAL · iOS \(UIDevice.current.systemVersion)")
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(ink.opacity(0.42))
                .accessibilityIdentifier("optics.captureMode")
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(paper.ignoresSafeArea())
        .preferredColorScheme(isDark ? .dark : .light)
        .accessibilityIdentifier("optics.page")
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Liquid Glass")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .tracking(-0.7)
                    .accessibilityIdentifier("optics.title")
                Text("An optical study")
                    .font(.system(size: 14))
                    .foregroundColor(ink.opacity(0.55))
            }
            Spacer(minLength: 12)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(ink.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Return to component gallery")
            .accessibilityIdentifier("optics.close")
        }
        .foregroundColor(ink)
    }

    private var opticalStage: some View {
        GeometryReader { geometry in
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isMoving)) { context in
                    let offset = isMoving
                        ? CGFloat(sin(context.date.timeIntervalSince(motionOrigin) * 1.15)) * 46
                        : 0
                    OpticalBackdrop(isDark: isDark, horizontalOffset: offset)
                }
                .accessibilityHidden(true)

                if showsGlass {
                    if isGrouped {
                        LiquidGlassGroup {
                            samples(width: geometry.size.width)
                        }
                    } else {
                        samples(width: geometry.size.width)
                    }
                }
            }
            .clipped()
            .overlay {
                Rectangle()
                    .strokeBorder(ink.opacity(0.08), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }

    private func configured(_ preset: LiquidGlassConfig) -> LiquidGlassConfig {
        var uniforms = preset.uniforms
        // This is the shader's material tint, not an opaque SwiftUI overlay.
        if isTinted {
            uniforms.materialTint = SIMD4<Float>(0.12, 0.48, 0.94, 0.19)
        }
        return LiquidGlassConfig(
            uniforms: uniforms,
            textureSizeCoefficient: preset.textureSizeCoefficient,
            textureScaleCoefficient: preset.textureScaleCoefficient,
            blurRadius: preset.blurRadius,
            shadowOverlay: preset.shadowOverlay
        )
    }

    private func samples(width: CGFloat) -> some View {
        let inset: CGFloat = 18
        let gap: CGFloat = 16
        let cardWidth = (width - inset * 2 - gap) / 2
        return VStack(spacing: 22) {
            HStack(spacing: gap) {
                sample("Regular", detail: "SOFT TRANSMISSION", icon: "square.on.square",
                       config: .regular, width: cardWidth, height: 112,
                       radius: isAngular ? 10 : 28, identifier: "optics.regular")
                sample("Lens", detail: "CLEAR REFRACTION", icon: "circle.circle",
                       config: .lens, width: cardWidth, height: 112,
                       radius: isAngular ? 10 : 28, identifier: "optics.lens")
            }
            HStack(spacing: 20) {
                sample("", detail: "", icon: "plus",
                       config: .lens, width: 88, height: 88,
                       radius: isAngular ? 10 : 44, identifier: "optics.round")
                sample("Capsule", detail: "", icon: "waveform",
                       config: .regular, width: max(110, width - inset * 2 - 108), height: 62,
                       radius: isAngular ? 10 : 31, identifier: "optics.capsule")
            }
            sample("Wide surface", detail: "", icon: "slider.horizontal.3",
                   config: .regular, width: width - inset * 2, height: 62,
                   radius: isAngular ? 8 : 26, identifier: "optics.wide")
        }
        .frame(width: width, height: 350)
    }

    private func sample(
        _ title: String, detail: String, icon: String,
        config: LiquidGlassConfig, width: CGFloat, height: CGFloat,
        radius: CGFloat, identifier: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: title.isEmpty ? 25 : 20, weight: .medium))
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .tracking(0.7)
            }
        }
        .foregroundColor(ink)
        .frame(width: width, height: height)
        .liquidGlass(config: configured(config), cornerRadius: radius,
                     backgroundCaptureFrameRate: 30)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title.isEmpty ? "Round lens" : title)
        .accessibilityIdentifier(identifier)
    }

    private var controls: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            control("Motion", icon: "play", value: isMoving, identifier: "optics.motion") {
                motionOrigin = Date()
                isMoving.toggle()
            }
            control("Dark", icon: "moon", value: isDark, identifier: "optics.dark") {
                isDark.toggle()
            }
            control("Blue tint", icon: "drop", value: isTinted, identifier: "optics.tint") {
                isTinted.toggle()
            }
            control("Tight corners", icon: "square", value: isAngular, identifier: "optics.corners") {
                isAngular.toggle()
            }
            control("Grouped", icon: "square.stack.3d.up", value: isGrouped, identifier: "optics.group") {
                isGrouped.toggle()
            }
            control("Glass", icon: "circle.lefthalf.filled", value: showsGlass, identifier: "optics.glass") {
                showsGlass.toggle()
            }
        }
    }

    private func control(
        _ title: String, icon: String, value: Bool,
        identifier: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 2)
                Circle()
                    .fill(value ? Color.blue : ink.opacity(0.16))
                    .frame(width: 6, height: 6)
            }
            .foregroundColor(ink)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value ? "On" : "Off")
        .accessibilityIdentifier(identifier)
    }
}

private struct OpticalBackdrop: View {
    var isDark: Bool
    var horizontalOffset: CGFloat

    var body: some View {
        Canvas { context, size in
            let foreground = isDark ? Color.white : Color.black
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(isDark ? Color(white: 0.12) : Color(white: 0.94)))

            // Solid, high-contrast geometry exposes refraction without relying on
            // a decorative gradient to imitate the material.
            let blueRect = CGRect(x: size.width * 0.28 + horizontalOffset,
                                  y: -30, width: 52, height: size.height + 60)
            context.fill(Path(blueRect), with: .color(Color(red: 0.12, green: 0.43, blue: 0.96)))
            let orangeRect = CGRect(x: -40, y: 180, width: size.width + 80, height: 44)
            context.fill(Path(orangeRect), with: .color(Color(red: 1, green: 0.36, blue: 0.13)))

            var grid = Path()
            let spacing: CGFloat = 22
            for index in -4...Int(size.width / spacing) + 4 {
                let x = CGFloat(index) * spacing + horizontalOffset
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
            }
            for index in 0...Int(size.height / spacing) + 1 {
                let y = CGFloat(index) * spacing
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(grid, with: .color(foreground.opacity(isDark ? 0.2 : 0.16)), lineWidth: 1)

            let words = ["LIQUID / 012", "Aa Bb 34567", "REFRACTION", "89 / GLASS"]
            for (index, word) in words.enumerated() {
                let text = Text(word)
                    .font(.system(size: index == 2 ? 35 : 31, weight: .heavy, design: .monospaced))
                    .foregroundColor(foreground.opacity(0.82))
                context.draw(text, at: CGPoint(x: 11 + horizontalOffset,
                                               y: 45 + CGFloat(index) * 85), anchor: .leading)
            }
        }
    }
}
