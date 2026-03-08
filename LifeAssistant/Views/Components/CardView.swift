//
//  CardView.swift
//  LifeAssistant
//

import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 4
    var shadowColor: Color = Color.black.opacity(0.1)
    var padding: CGFloat = 16
    
    init(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 4,
        shadowColor: Color = Color.black.opacity(0.1),
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
}

struct GradientCardView<Content: View>: View {
    let content: Content
    var colors: [Color] = [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 8
    var padding: CGFloat = 20
    
    init(
        colors: [Color] = [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(cornerRadius)
            .shadow(color: colors.first?.opacity(0.3) ?? Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 4)
    }
}

struct GlassCardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var blurRadius: CGFloat = 10
    var padding: CGFloat = 20
    
    init(
        cornerRadius: CGFloat = 20,
        blurRadius: CGFloat = 10,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.blurRadius = blurRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct CategoryBadge: View {
    let title: String
    let color: Color
    var icon: String? = nil
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.fontSize))
            }
            Text(title)
                .font(.system(size: size.fontSize, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(size.padding)
        .background(color)
        .cornerRadius(size.cornerRadius)
    }
}

struct StatusIndicator: View {
    let status: String
    let color: Color
    var showDot: Bool = true
    
    var body: some View {
        HStack(spacing: 6) {
            if showDot {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 普通卡片
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("普通卡片")
                            .font(.headline)
                        Text("这是一个普通的卡片视图")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 渐变卡片
                GradientCardView(colors: [.blue, .purple]) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("渐变卡片")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("带有渐变背景的卡片")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                
                // 玻璃拟态卡片
                GlassCardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("玻璃卡片")
                            .font(.headline)
                        Text("使用毛玻璃效果的卡片")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 徽章
                HStack(spacing: 12) {
                    CategoryBadge(title: "餐饮", color: .red, icon: "fork.knife")
                    CategoryBadge(title: "交通", color: .blue, icon: "car.fill")
                    CategoryBadge(title: "购物", color: .green, icon: "bag.fill")
                }
                .padding(.horizontal)
                
                // 状态指示器
                HStack(spacing: 12) {
                    StatusIndicator(status: "进行中", color: .blue)
                    StatusIndicator(status: "已完成", color: .green)
                    StatusIndicator(status: "紧急", color: .red)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.gray.opacity(0.1))
    }
}
