//
//  EmptyStateView.swift
//  LifeAssistant
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(accentColor)
            }
            
            // 标题
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // 按钮
            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus")
                        Text(buttonTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
    }
}

struct LoadingView: View {
    var message: String = "加载中..."
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("出错了")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let action = retryAction {
                Button(action: action) {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView(
                icon: "clipboard.list",
                title: "暂无待办事项",
                message: "您还没有添加任何待办事项，点击下方的按钮开始创建吧！",
                buttonTitle: "添加待办",
                buttonAction: {},
                accentColor: .blue
            )
            
            LoadingView(message: "正在识别图片...", accentColor: .purple)
                .previewLayout(.sizeThatFits)
            
            ErrorView(
                message: "无法连接到服务器，请检查网络设置后重试。",
                retryAction: {}
            )
        }
    }
}
