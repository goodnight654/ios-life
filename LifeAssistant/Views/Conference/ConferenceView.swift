//
//  ConferenceView.swift
//  LifeAssistant
//

import SwiftUI

struct ConferenceView: View {
    @StateObject private var service = ConferenceService()
    @State private var showingAddSheet = false
    @State private var selectedFilter: ConferenceFilter = .all
    @State private var selectedCategory: AcademicCategory?
    @State private var selectedSort: ConferenceSortOption = .ddlAscending
    @State private var selectedConference: Conference?
    
    var filteredConferences: [Conference] {
        let categoryFiltered = selectedCategory != nil
            ? service.filteredByCategory(selectedCategory)
            : service.conferences
        
        switch selectedFilter {
        case .all:
            return categoryFiltered
        case .conference, .journal, .workshop:
            return categoryFiltered.filter { conference in
                switch selectedFilter {
                case .conference: return conference.type == .conference
                case .journal: return conference.type == .journal
                case .workshop: return conference.type == .workshop
                default: return true
                }
            }
        case .urgent:
            return categoryFiltered.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .overdue }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 统计概览
                    ConferenceStatisticsCard(statistics: service.statistics)
                    
                    // 分类选择器
                    CategorySelector(
                        selectedCategory: $selectedCategory,
                        statistics: service.statistics
                    )
                    .padding(.horizontal)
                    
                    // 筛选和排序
                    ConferenceFilterBar(
                        selectedFilter: $selectedFilter,
                        selectedSort: $selectedSort
                    )
                    .padding(.horizontal)
                    
                    // 会议列表
                    ConferenceListSection(
                        conferences: filteredConferences,
                        onDelete: { conference in
                            service.deleteConference(conference)
                        },
                        onEdit: { conference in
                            selectedConference = conference
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("会议/期刊")
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
                AddConferenceView(service: service)
            }
            .sheet(item: $selectedConference) { conference in
                EditConferenceView(service: service, conference: conference)
            }
        }
    }
}

// MARK: - 统计卡片
struct ConferenceStatisticsCard: View {
    let statistics: ConferenceStatistics
    
    var body: some View {
        GradientCardView(
            colors: [
                Color(hex: "0891B2"),
                Color(hex: "0E7490")
            ],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("学术追踪")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(statistics.total) 个会议/期刊")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 紧急数量
                    if statistics.urgentCount > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("即将截止")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(statistics.urgentCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "fbbf24"))
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 类型统计
                HStack(spacing: 0) {
                    StatBox(value: statistics.conferenceCount, label: "学术会议", color: .white)
                    Divider()
                        .background(Color.white.opacity(0.3))
                    StatBox(value: statistics.journalCount, label: "期刊投稿", color: .white)
                    Divider()
                        .background(Color.white.opacity(0.3))
                    StatBox(value: statistics.workshopCount, label: "研讨会", color: .white)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 分类选择器
struct CategorySelector: View {
    @Binding var selectedCategory: AcademicCategory?
    let statistics: ConferenceStatistics
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 全部按钮
                CategoryFilterButton(
                    title: "全部",
                    count: statistics.total,
                    color: .gray,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(AcademicCategory.allCases) { category in
                    let count = statistics.categoryBreakdown[category] ?? 0
                    CategoryFilterButton(
                        title: category.rawValue,
                        count: count,
                        color: Color(hex: category.color),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? color
                    : color.opacity(0.1)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - 筛选栏
struct ConferenceFilterBar: View {
    @Binding var selectedFilter: ConferenceFilter
    @Binding var selectedSort: ConferenceSortOption
    
    var body: some View {
        VStack(spacing: 12) {
            // 类型筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ConferenceFilter.allCases) { filter in
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
                    ForEach(ConferenceSortOption.allCases) { option in
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
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 会议列表
struct ConferenceListSection: View {
    let conferences: [Conference]
    let onDelete: (Conference) -> Void
    let onEdit: (Conference) -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("会议/期刊列表")
                        .font(.headline)
                    Spacer()
                    Text("\(conferences.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if conferences.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "暂无记录",
                        message: "点击右上角添加您的第一个会议或期刊",
                        buttonTitle: "添加记录",
                        buttonAction: {},
                        accentColor: .cyan
                    )
                    .frame(height: 200)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(conferences) { conference in
                            ConferenceCard(conference: conference)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onEdit(conference)
                                }
                                .contextMenu {
                                    Button(action: { onEdit(conference) }) {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        onDelete(conference)
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

struct ConferenceCard: View {
    let conference: Conference
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 类型图标
                ZStack {
                    Circle()
                        .fill(Color(hex: conference.category.color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: conference.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: conference.category.color))
                }
                
                // 名称和分类
                VStack(alignment: .leading, spacing: 4) {
                    Text(conference.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        CategoryBadge(
                            title: conference.category.rawValue,
                            color: Color(hex: conference.category.color),
                            size: .small
                        )
                        
                        Text(conference.type.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 紧急程度
                if conference.urgencyLevel != .normal {
                    Image(systemName: conference.urgencyLevel == .overdue ? "exclamationmark.circle.fill" : "clock.badge.exclamationmark.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: conference.urgencyLevel.color))
                }
            }
            
            Divider()
            
            // DDL 和日期信息
            HStack(spacing: 16) {
                if let daysUntilDDL = conference.daysUntilDDL {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(Color(hex: conference.urgencyLevel.color))
                        
                        if daysUntilDDL < 0 {
                            Text("已逾期 \(-daysUntilDDL) 天")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "ef4444"))
                        } else if daysUntilDDL == 0 {
                            Text("今天截止")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "ef4444"))
                        } else {
                            Text("\(daysUntilDDL) 天后截止")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: conference.urgencyLevel.color))
                        }
                    }
                }
                
                if conference.startDate != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(conference.dateRangeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !conference.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(conference.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 网站链接
            if !conference.website.isEmpty {
                Link(destination: URL(string: conference.website)!) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("访问官网")
                            .font(.caption)
                    }
                    .foregroundColor(.cyan)
                }
            }
            
            // 备注
            if !conference.notes.isEmpty {
                Text(conference.notes)
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
                .stroke(Color(hex: conference.category.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 添加/编辑视图
struct AddConferenceView: View {
    @ObservedObject var service: ConferenceService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedType: ConferenceType = .conference
    @State private var selectedCategory: AcademicCategory = .ai
    @State private var hasDDL = true
    @State private var ddl = Date()
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var location = ""
    @State private var website = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                    
                    Picker("类型", selection: $selectedType) {
                        ForEach(ConferenceType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(AcademicCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("截止日期")) {
                    Toggle("设置截止日期", isOn: $hasDDL)
                    if hasDDL {
                        DatePicker("截止日期", selection: $ddl, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("会议日期")) {
                    Toggle("设置开始日期", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("开始日期", selection: $startDate, displayedComponents: [.date])
                        
                        Toggle("设置结束日期", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("结束日期", selection: $endDate, displayedComponents: [.date])
                        }
                    }
                }
                
                Section(header: Text("详细信息")) {
                    TextField("地点", text: $location)
                    TextField("网站链接", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("添加会议/期刊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveConference()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveConference() {
        let conference = Conference(
            name: name,
            type: selectedType,
            category: selectedCategory,
            ddl: hasDDL ? ddl : nil,
            startDate: hasStartDate ? startDate : nil,
            endDate: hasEndDate && hasStartDate ? endDate : nil,
            location: location,
            website: website,
            notes: notes
        )
        
        service.addConference(conference)
        dismiss()
    }
}

struct EditConferenceView: View {
    @ObservedObject var service: ConferenceService
    let conference: Conference
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedType: ConferenceType
    @State private var selectedCategory: AcademicCategory
    @State private var hasDDL: Bool
    @State private var ddl: Date
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var location: String
    @State private var website: String
    @State private var notes: String
    
    init(service: ConferenceService, conference: Conference) {
        self.service = service
        self.conference = conference
        _name = State(initialValue: conference.name)
        _selectedType = State(initialValue: conference.type)
        _selectedCategory = State(initialValue: conference.category)
        _hasDDL = State(initialValue: conference.ddl != nil)
        _ddl = State(initialValue: conference.ddl ?? Date())
        _hasStartDate = State(initialValue: conference.startDate != nil)
        _startDate = State(initialValue: conference.startDate ?? Date())
        _hasEndDate = State(initialValue: conference.endDate != nil)
        _endDate = State(initialValue: conference.endDate ?? Date())
        _location = State(initialValue: conference.location)
        _website = State(initialValue: conference.website)
        _notes = State(initialValue: conference.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                    
                    Picker("类型", selection: $selectedType) {
                        ForEach(ConferenceType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(AcademicCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("截止日期")) {
                    Toggle("设置截止日期", isOn: $hasDDL)
                    if hasDDL {
                        DatePicker("截止日期", selection: $ddl, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("会议日期")) {
                    Toggle("设置开始日期", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("开始日期", selection: $startDate, displayedComponents: [.date])
                        
                        Toggle("设置结束日期", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("结束日期", selection: $endDate, displayedComponents: [.date])
                        }
                    }
                }
                
                Section(header: Text("详细信息")) {
                    TextField("地点", text: $location)
                    TextField("网站链接", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(role: .destructive) {
                        service.deleteConference(conference)
                        dismiss()
                    } label: {
                        Text("删除记录")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("编辑会议/期刊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateConference()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updateConference() {
        var updatedConference = conference
        updatedConference.name = name
        updatedConference.type = selectedType
        updatedConference.category = selectedCategory
        updatedConference.ddl = hasDDL ? ddl : nil
        updatedConference.startDate = hasStartDate ? startDate : nil
        updatedConference.endDate = hasEndDate && hasStartDate ? endDate : nil
        updatedConference.location = location
        updatedConference.website = website
        updatedConference.notes = notes
        
        service.updateConference(updatedConference)
        dismiss()
    }
}

struct ConferenceView_Previews: PreviewProvider {
    static var previews: some View {
        ConferenceView()
    }
}
