//
//  ProgressBar.swift
//  LifeAssistant
//

import SwiftUI

struct ProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var foregroundColor: Color = .blue
    var animated: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                // 进度条
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                foregroundColor.opacity(0.8),
                                foregroundColor
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(CGFloat(progress) * geometry.size.width, geometry.size.width)))
                    .animation(animated ? .easeInOut(duration: 0.3) : nil, value: progress)
            }
        }
        .frame(height: height)
    }
}

struct CircularProgressView: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var foregroundColor: Color = .blue
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var showPercentage: Bool = true
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            foregroundColor.opacity(0.6),
                            foregroundColor,
                            foregroundColor.opacity(0.6)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // 百分比文字
            if showPercentage {
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(foregroundColor)
                    Text("%")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(foregroundColor.opacity(0.8))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ProgressBar(progress: 0.75, height: 10)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                CircularProgressView(progress: 0.3, size: 80, foregroundColor: .red)
                CircularProgressView(progress: 0.65, size: 80, foregroundColor: .orange)
                CircularProgressView(progress: 0.9, size: 80, foregroundColor: .green)
            }
        }
        .padding()
    }
}
