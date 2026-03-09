//
//  InterviewView.swift
//  LifeAssistant
//

import SwiftUI

struct InterviewView: View {
    @StateObject private var service = InterviewService()
    @State private var showingAddSheet = false
    @State private var selectedFilter: InterviewFilter = .all
    @State private var selectedSort: InterviewSortOption = .ddlAscending
    @State private var selectedInterview: Interview?
    
    var filteredInterviews: [Interview] {
        service.filteredInterviews(filter: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 统计概览
                        InterviewStatisticsCard(statistics: service.statistics)
                            .id("top")

                        // 筛选和排序
                        InterviewFilterBar(
                            selectedFilter: $selectedFilter,
                            selectedSort: $selectedSort
                        )
                        .padding(.horizontal)

                        // 面试列表
                        InterviewListSection(
                            interviews: filteredInterviews,
                            onStatusChange: { interview, status in
                                service.updateStatus(for: interview, to: status)
                            },
                            onDelete: { interview in
                                service.deleteInterview(interview)
                            },
                            onEdit: { interview in
                                selectedInterview = interview
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
            .navigationTitle("面试汇总")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInterviewView(service: service)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(item: $selectedInterview) { interview in
                EditInterviewView(service: service, interview: interview)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
        }
    }
}

// MARK: - 统计卡片
struct InterviewStatisticsCard: View {
    let statistics: InterviewStatistics
    
    var body: some View {
        GradientCardView(
            colors: [
                Color(hex: "4F46E5"),
                Color(hex: "7C3AED")
            ],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("面试进度")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(statistics.total) 家公司")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Offer 率
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Offer 率")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(String(format: "%.0f%%", statistics.successRate * 100))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "4ade80"))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 统计项
                HStack(spacing: 0) {
                    StatBox(value: statistics.active, label: "进行中", color: .white)
                    Divider()
                        .background(Color.white.opacity(0.3))
                    StatBox(value: statistics.offerCount, label: "已 Offer", color: Color(hex: "4ade80"))
                    Divider()
                        .background(Color.white.opacity(0.3))
                    StatBox(value: statistics.rejectedCount, label: "已拒绝", color: Color(hex: "f87171"))
                    Divider()
                        .background(Color.white.opacity(0.3))
                    StatBox(value: statistics.urgentCount, label: "紧急", color: Color(hex: "fbbf24"))
                }
            }
        }
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 筛选栏
struct InterviewFilterBar: View {
    @Binding var selectedFilter: InterviewFilter
    @Binding var selectedSort: InterviewSortOption
    @State private var showingSortMenu = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 筛选器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(InterviewFilter.allCases) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            count: 0,
                            isSelected: selectedFilter == filter,
                            color: filter.color
                        ) {
                            withAnimation(.spring()) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
            
            // 排序选择
            HStack {
                Text("排序:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(InterviewSortOption.allCases) { option in
                        Button(option.rawValue) {
                            selectedSort = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSort.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 面试列表
struct InterviewListSection: View {
    let interviews: [Interview]
    let onStatusChange: (Interview, InterviewStatus) -> Void
    let onDelete: (Interview) -> Void
    let onEdit: (Interview) -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("面试列表")
                        .font(.headline)
                    Spacer()
                    Text("\(interviews.count) 家")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if interviews.isEmpty {
                    EmptyStateView(
                        icon: "briefcase",
                        title: "暂无面试",
                        message: "点击右上角添加您的第一个面试记录",
                        buttonTitle: "添加面试",
                        buttonAction: {},
                        accentColor: .indigo
                    )
                    .frame(height: 200)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(interviews) { interview in
                            InterviewCard(
                                interview: interview,
                                onStatusChange: { status in
                                    onStatusChange(interview, status)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onEdit(interview)
                            }
                            .contextMenu {
                                Button(action: { onEdit(interview) }) {
                                    Label("编辑", systemImage: "pencil")
                                }
                                
                                Menu("更新状态") {
                                    ForEach(InterviewStatus.allCases) { status in
                                        Button(status.title) {
                                            onStatusChange(interview, status)
                                        }
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    onDelete(interview)
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

struct InterviewCard: View {
    let interview: Interview
    let onStatusChange: (InterviewStatus) -> Void
    @State private var showingStatusMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 公司名
                VStack(alignment: .leading, spacing: 4) {
                    Text(interview.company)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(interview.position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态
                Menu {
                    ForEach(InterviewStatus.allCases) { status in
                        Button(status.title) {
                            onStatusChange(status)
                        }
                    }
                } label: {
                    StatusIndicator(
                        status: interview.status.title,
                        color: Color(hex: interview.status.color)
                    )
                }
            }
            
            Divider()
            
            // DDL 和地点
            HStack(spacing: 16) {
                // DDL
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(Color(hex: interview.urgencyLevel.color))
                    Text(formatDDL(interview.ddl))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: interview.urgencyLevel.color))
                }
                
                if !interview.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(interview.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !interview.salary.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(interview.salary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 紧急程度标签
                if interview.urgencyLevel != .normal {
                    Text(interview.urgencyLevel.description)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: interview.urgencyLevel.color))
                        .cornerRadius(4)
                }
            }
            
            // 备注
            if !interview.notes.isEmpty {
                Text(interview.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: interview.status.color).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDDL(_ date: Date) -> String {
        let calendar = Calendar.current
        let days = interview.daysUntilDDL
        
        if calendar.isDateInToday(date) {
            return "今天截止"
        } else if calendar.isDateInTomorrow(date) {
            return "明天截止"
        } else if days > 0 {
            return "\(days) 天后截止"
        } else if days == 0 {
            return "今天截止"
        } else {
            return "已逾期 \(-days) 天"
        }
    }
}

// MARK: - 添加/编辑视图
struct AddInterviewView: View {
    @ObservedObject var service: InterviewService
    @Environment(\.dismiss) var dismiss
    
    @State private var company = ""
    @State private var position = ""
    @State private var ddl = Date()
    @State private var selectedStatus: InterviewStatus = .applied
    @State private var location = ""
    @State private var salary = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("公司名称", text: $company)
                    TextField("职位", text: $position)
                    
                    DatePicker("截止日期", selection: $ddl, displayedComponents: [.date])
                    
                    Picker("当前状态", selection: $selectedStatus) {
                        ForEach(InterviewStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }
                
                Section(header: Text("详细信息")) {
                    TextField("地点", text: $location)
                    TextField("薪资范围", text: $salary)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("添加面试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveInterview()
                    }
                    .disabled(company.isEmpty || position.isEmpty)
                }
            }
        }
    }
    
    private func saveInterview() {
        let interview = Interview(
            company: company,
            position: position,
            ddl: ddl,
            status: selectedStatus,
            notes: notes,
            location: location,
            salary: salary
        )
        
        service.addInterview(interview)
        dismiss()
    }
}

struct EditInterviewView: View {
    @ObservedObject var service: InterviewService
    let interview: Interview
    @Environment(\.dismiss) var dismiss
    
    @State private var company: String
    @State private var position: String
    @State private var ddl: Date
    @State private var selectedStatus: InterviewStatus
    @State private var location: String
    @State private var salary: String
    @State private var notes: String
    
    init(service: InterviewService, interview: Interview) {
        self.service = service
        self.interview = interview
        _company = State(initialValue: interview.company)
        _position = State(initialValue: interview.position)
        _ddl = State(initialValue: interview.ddl)
        _selectedStatus = State(initialValue: interview.status)
        _location = State(initialValue: interview.location)
        _salary = State(initialValue: interview.salary)
        _notes = State(initialValue: interview.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("公司名称", text: $company)
                    TextField("职位", text: $position)
                    
                    DatePicker("截止日期", selection: $ddl, displayedComponents: [.date])
                    
                    Picker("当前状态", selection: $selectedStatus) {
                        ForEach(InterviewStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }
                
                Section(header: Text("详细信息")) {
                    TextField("地点", text: $location)
                    TextField("薪资范围", text: $salary)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(role: .destructive) {
                        service.deleteInterview(interview)
                        dismiss()
                    } label: {
                        Text("删除记录")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("编辑面试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateInterview()
                    }
                    .disabled(company.isEmpty || position.isEmpty)
                }
            }
        }
    }
    
    private func updateInterview() {
        var updatedInterview = interview
        updatedInterview.company = company
        updatedInterview.position = position
        updatedInterview.ddl = ddl
        updatedInterview.status = selectedStatus
        updatedInterview.location = location
        updatedInterview.salary = salary
        updatedInterview.notes = notes
        
        service.updateInterview(updatedInterview)
        dismiss()
    }
}

struct InterviewView_Previews: PreviewProvider {
    static var previews: some View {
        InterviewView()
    }
}
