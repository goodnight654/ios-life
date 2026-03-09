//
//  HomeView.swift
//  LifeAssistant
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var accountService = AccountService()
    @StateObject private var todoService = TodoService()
    @StateObject private var interviewService = InterviewService()
    @StateObject private var conferenceService = ConferenceService()
    @StateObject private var progressService = ProgressService()

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // 欢迎卡片
                        WelcomeCard()
                            .id("top")

                        // 快速概览
                        QuickOverviewGrid(
                            accountService: accountService,
                            todoService: todoService,
                            interviewService: interviewService,
                            conferenceService: conferenceService,
                            progressService: progressService,
                            onTabSelect: { tab in
                                withAnimation {
                                    selectedTab = tab
                                }
                            }
                        )

                        // 本月记账概览
                        AccountSummaryCard(service: accountService)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 1
                                }
                            }

                        // 待办事项概览
                        TodoSummaryCard(service: todoService)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 2
                                }
                            }

                        // 面试进度
                        InterviewSummaryCard(service: interviewService)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 4
                                }
                            }

                        // 会议/期刊提醒
                        ConferenceSummaryCard(service: conferenceService)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 5
                                }
                            }

                        // 目标进度
                        ProgressSummaryCard(service: progressService)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 6
                                }
                            }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .navigationTitle("生活助手")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 欢迎卡片
struct WelcomeCard: View {
    var body: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        let icon: String

        if hour < 12 {
            greeting = "早上好"
            icon = "sunrise.fill"
        } else if hour < 18 {
            greeting = "下午好"
            icon = "sun.max.fill"
        } else {
            greeting = "晚上好"
            icon = "moon.stars.fill"
        }

        return GradientCardView(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(formatDate(Date()))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 快速概览网格
struct QuickOverviewGrid: View {
    @ObservedObject var accountService: AccountService
    @ObservedObject var todoService: TodoService
    @ObservedObject var interviewService: InterviewService
    @ObservedObject var conferenceService: ConferenceService
    @ObservedObject var progressService: ProgressService
    var onTabSelect: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickStatCard(
                title: "本月支出",
                value: String(format: "¥%.0f", accountService.getStatistics(for: .month).totalExpense),
                icon: "dollarsign.circle.fill",
                color: .red
            )
            .onTapGesture {
                onTabSelect(1)
            }

            QuickStatCard(
                title: "待办事项",
                value: "\(todoService.progress.remaining)",
                icon: "checklist",
                color: .green
            )
            .onTapGesture {
                onTabSelect(2)
            }

            QuickStatCard(
                title: "面试进度",
                value: "\(interviewService.statistics.total)",
                icon: "briefcase.fill",
                color: .blue
            )
            .onTapGesture {
                onTabSelect(4)
            }

            QuickStatCard(
                title: "目标进度",
                value: "\(progressService.completedGoals)/\(progressService.totalGoals)",
                icon: "target",
                color: .orange
            )
            .onTapGesture {
                onTabSelect(6)
            }
        }
        .padding(.horizontal)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 记账概览卡片
struct AccountSummaryCard: View {
    @ObservedObject var service: AccountService

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("本月记账")
                        .font(.headline)
                    Spacer()
                    Text("查看全部 →")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let stats = service.getStatistics(for: .month)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("收入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "¥%.2f", stats.totalIncome))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("支出")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "¥%.2f", stats.totalExpense))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("结余")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "¥%.2f", stats.balance))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(stats.balance >= 0 ? .green : .red)
                    }
                }

                // 最近3笔记录
                if !service.records.isEmpty {
                    Divider()

                    Text("最近记录")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(service.records.prefix(3)) { record in
                        HStack {
                            Image(systemName: record.category.icon)
                                .font(.caption)
                                .foregroundColor(Color(hex: record.category.color))
                                .frame(width: 20)

                            Text(record.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(String(format: "¥%.0f", record.amount))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(record.isExpense ? .red : .green)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 待办概览卡片
struct TodoSummaryCard: View {
    @ObservedObject var service: TodoService

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("待办事项")
                        .font(.headline)
                    Spacer()
                    Text("\(service.progress.completed)/\(service.progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 进度条
                VStack(spacing: 8) {
                    HStack {
                        Text("完成进度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(service.progress.percentage * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    ProgressBar(
                        progress: service.progress.percentage,
                        height: 8,
                        foregroundColor: .green
                    )
                }

                // 待办状态统计
                HStack(spacing: 16) {
                    Label("\(service.progress.completed) 已完成", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)

                    Label("\(service.progress.remaining) 待完成", systemImage: "circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                // 最近待办
                let recentTodos = service.todos.prefix(3)
                if !recentTodos.isEmpty {
                    Divider()

                    ForEach(recentTodos) { todo in
                        HStack {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? .green : Color(hex: todo.priority.color))

                            Text(todo.title)
                                .font(.caption)
                                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                .strikethrough(todo.isCompleted)

                            Spacer()

                            if let dueDate = todo.dueDate {
                                Text(formatDueDate(dueDate, isOverdue: todo.isOverdue))
                                    .font(.caption2)
                                    .foregroundColor(todo.isOverdue ? .red : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatDueDate(_ date: Date, isOverdue: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 面试概览卡片
struct InterviewSummaryCard: View {
    @ObservedObject var service: InterviewService

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("面试进度")
                        .font(.headline)
                    Spacer()
                    Text("\(service.statistics.total) 家公司")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 状态统计
                HStack(spacing: 12) {
                    StatusChip(count: service.statistics.active, label: "进行中", color: .blue)
                    StatusChip(count: service.statistics.offerCount, label: "Offer", color: .green)
                    StatusChip(count: service.statistics.rejectedCount, label: "拒绝", color: .red)
                }

                // 最近面试
                let recentInterviews = service.interviews.prefix(3)
                if !recentInterviews.isEmpty {
                    Divider()

                    ForEach(recentInterviews) { interview in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(interview.company)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Text(interview.position)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(interview.status.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: interview.status.color))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: interview.status.color).opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct StatusChip: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 会议概览卡片
struct ConferenceSummaryCard: View {
    @ObservedObject var service: ConferenceService

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Text("会议/期刊")
                        .font(.headline)
                    Spacer()
                    Text("\(service.statistics.total) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 紧急提醒
                if service.statistics.urgentCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(service.statistics.urgentCount) 个即将截止或已逾期")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // 最近会议
                let recentConferences = service.conferences.prefix(3)
                if !recentConferences.isEmpty {
                    Divider()

                    ForEach(recentConferences) { conference in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conference.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Text(conference.type.title)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let days = conference.daysUntilDDL {
                                Text(days < 0 ? "逾期\(-days)天" : "\(days)天后")
                                    .font(.caption2)
                                    .foregroundColor(days < 0 ? .red : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 目标进度概览卡片
struct ProgressSummaryCard: View {
    @ObservedObject var service: ProgressService

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("目标进度")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(service.averageProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                // 总体进度
                ProgressBar(
                    progress: service.averageProgress,
                    height: 10,
                    foregroundColor: .orange
                )

                HStack(spacing: 16) {
                    Label("\(service.completedGoals) 已完成", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)

                    Label("\(service.inProgressGoals) 进行中", systemImage: "arrow.forward.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Label("\(service.totalGoals - service.completedGoals - service.inProgressGoals) 未开始", systemImage: "circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 最近目标
                let recentGoals = service.goals.prefix(3)
                if !recentGoals.isEmpty {
                    Divider()

                    ForEach(recentGoals) { goal in
                        HStack {
                            Text(goal.title)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(goal.progressPercentage)%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: goal.statusColor))
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
    }
}