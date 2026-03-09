//
//  ProgressView.swift
// LifeAssistant
//

import SwiftUI

struct ProgressTrackingView: View {
    @StateObject private var service = ProgressService()
    @State private var showingAddSheet = false
    @State private var selectedGoal: ProgressGoal?
    @State private var showingEditSheet = false

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // 统计概览
                        ProgressStatisticsCard(service: service)
                            .id("top")

                        // 目标列表
                        ProgressGoalsSection(
                            goals: service.goals,
                            onEdit: { goal in
                                selectedGoal = goal
                                showingEditSheet = true
                            },
                            onDelete: { goal in
                                service.deleteGoal(goal)
                            },
                            onUpdateProgress: { goal, progress in
                                service.updateProgress(for: goal.id, progress: progress)
                            }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .navigationTitle("进度跟踪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddProgressGoalView(service: service)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(item: $selectedGoal) { goal in
                EditProgressGoalView(service: service, goal: goal)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
        }
    }
}

// MARK: - 统计卡片
struct ProgressStatisticsCard: View {
    @ObservedObject var service: ProgressService

    var body: some View {
        GradientCardView(
            colors: [Color(hex: "f97316"), Color(hex: "fb923c")],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("\(service.totalGoals)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("总目标")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(service.completedGoals)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("已完成")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(service.inProgressGoals)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("进行中")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                if service.totalGoals > 0 {
                    Divider()
                        .background(Color.white.opacity(0.3))

                    VStack(spacing: 8) {
                        HStack {
                            Text("总体进度")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(service.averageProgress * 100))%")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        ProgressView(value: service.averageProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .background(Color.white.opacity(0.2))
                }
            }
        }
        .padding(.vertical, 8)
    }
        .padding(.horizontal)
}
}

// MARK: - 目标列表
struct ProgressGoalsSection: View {
    let goals: [ProgressGoal]
    let onEdit: (ProgressGoal) -> Void
    let onDelete: (ProgressGoal) -> Void
    let onUpdateProgress: (ProgressGoal, Double) -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("目标列表")
                        .font(.headline)
                    Spacer()
                    Text("\(goals.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if goals.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "暂无目标",
                        message: "点击右上角添加您的第一个目标",
                        accentColor: .orange
                    )
                    .frame(height: 180)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(goals) { goal in
                            ProgressGoalCard(
                                goal: goal,
                                onEdit: { onEdit(goal) },
                                onUpdateProgress: { progress in
                                    onUpdateProgress(goal, progress)
                                }
                            )
                            .contextMenu {
                                Button(action: { onEdit(goal) }) {
                                    Label("编辑", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    onDelete(goal)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 目标卡片
struct ProgressGoalCard: View {
    let goal: ProgressGoal
    let onEdit: () -> Void
    let onUpdateProgress: (Double) -> Void

    @State private var editingProgress: Double

    init(goal: ProgressGoal, onEdit: @escaping () -> Void, onUpdateProgress: @escaping (Double) -> Void) {
        self.goal = goal
        self.onEdit = onEdit
        self.onUpdateProgress = onUpdateProgress
        self._editingProgress = State(initialValue: goal.progress)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    if !goal.notes.isEmpty {
                        Text(goal.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // 状态标签
                Text(goal.statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: goal.statusColor))
                    .cornerRadius(8)
            }

            // 进度条
            VStack(spacing: 8) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(goal.progressPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: goal.statusColor))
                }

                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: goal.statusColor)))
                    .background(Color.gray.opacity(0.2))
            }

            // 快速调整进度
            HStack(spacing: 8) {
                Text("快速调整:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                    Button(action: {
                        onUpdateProgress(Double(value) / 100.0)
                    }) {
                        Text("\(value)%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Int(goal.progress * 100) == value ? .white : Color(hex: goal.statusColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Int(goal.progress * 100) == value ? Color(hex: goal.statusColor) : Color(hex: goal.statusColor).opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }

            // 创建时间
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("创建于 \(formatDate(goal.createdAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("更新于 \(formatDate(goal.updatedAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onTapGesture {
            onEdit()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 添加目标视图
struct AddProgressGoalView: View {
    @ObservedObject var service: ProgressService
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var progress: Double = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("目标名称", text: $title)

                    TextField("备注说明", text: $notes)
                        .lineLimit(3...5)
                }

                Section(header: Text("初始进度")) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("进度: \(Int(progress * 100))%")
                                .font(.headline)
                            Spacer()
                        }

                        Slider(value: $progress, in: 0...1, step: 0.05)
                            .accentColor(.orange)

                        HStack(spacing: 8) {
                            ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                                Button("\(value)%") {
                                    progress = Double(value) / 100.0
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let goal = ProgressGoal(
                            title: title,
                            notes: notes,
                            progress: progress
                        )
                        service.addGoal(goal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 编辑目标视图
struct EditProgressGoalView: View {
    @ObservedObject var service: ProgressService
    let goal: ProgressGoal
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var progress: Double

    init(service: ProgressService, goal: ProgressGoal) {
        self.service = service
        self.goal = goal
        self._title = State(initialValue: goal.title)
        self._notes = State(initialValue: goal.notes)
        self._progress = State(initialValue: goal.progress)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("目标名称", text: $title)

                    TextField("备注说明", text: $notes)
                        .lineLimit(3...5)
                }

                Section(header: Text("进度")) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("进度: \(Int(progress * 100))%")
                                .font(.headline)
                            Spacer()
                        }

                        Slider(value: $progress, in: 0...1, step: 0.05)
                            .accentColor(.orange)

                        HStack(spacing: 8) {
                            ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                                Button("\(value)%") {
                                    progress = Double(value) / 100.0
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        service.deleteGoal(goal)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除目标")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let updatedGoal = ProgressGoal(
                            id: goal.id,
                            title: title,
                            notes: notes,
                            progress: progress,
                            createdAt: goal.createdAt,
                            updatedAt: Date()
                        )
                        service.updateGoal(updatedGoal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ProgressTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTrackingView()
    }
}