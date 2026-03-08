//
//  ContentView.swift
//  LifeAssistant
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 记账 Tab
            AccountView()
                .tabItem {
                    Label("记账", systemImage: "dollarsign.circle.fill")
                }
                .tag(0)
            
            // 待办 Tab
            TodoView()
                .tabItem {
                    Label("待办", systemImage: "checklist")
                }
                .tag(1)
            
            // AI 识图 Tab
            AIRecognitionView()
                .tabItem {
                    Label("AI识图", systemImage: "camera.viewfinder")
                }
                .tag(2)
            
            // 面试 Tab
            InterviewView()
                .tabItem {
                    Label("面试", systemImage: "briefcase.fill")
                }
                .tag(3)
            
            // 会议 Tab
            ConferenceView()
                .tabItem {
                    Label("会议", systemImage: "calendar.badge.clock")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // 设置 TabBar 样式
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - 自定义 TabBar 样式（可选）
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String, color: Color)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 22, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? tabs[index].color : .gray)
                        
                        Text(tabs[index].title)
                            .font(.caption2)
                            .fontWeight(selectedTab == index ? .medium : .regular)
                            .foregroundColor(selectedTab == index ? tabs[index].color : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
