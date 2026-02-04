//
//  LiquidGlassToggle.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃开关
//

import SwiftUI

/// 液态玻璃开关
public struct LiquidGlassToggle: View {
    
    @Binding var isOn: Bool
    var onColor: Color
    
    public init(isOn: Binding<Bool>, onColor: Color = .green) {
        self._isOn = isOn
        self.onColor = onColor
    }
    
    public var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? onColor.opacity(0.5) : Color.white.opacity(0.1))
                .frame(width: 52, height: 32)
            
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .offset(x: isOn ? 10 : -10)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .liquidGlass(cornerRadius: 16)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }
    }
}
