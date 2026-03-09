//
//  TodoView.swift
//  LifeAssistant
//

import SwiftUI

struct TodoView: View {
    @StateObject private var service = TodoService()
    @State private var showingAddSheet = false
    @State private var selectedFilter: TodoFilter = .all
    @State private var selectedTodo: TodoItem?
    
    var filteredTodos: [TodoItem] {
        service.filteredTodos(filter: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 进度概览
                        TodoProgressCard(progress: service.progress)
                            .id("top")

                        // 快速筛选
                        QuickFilterBar(selectedFilter: $selectedFilter, service: service)
                            .padding(.horizontal)

                        // 待办列表
                        TodoListSection(
                            todos: filteredTodos,
                            onToggle: { todo in
                                service.toggleComplete(todo)
                            },
                            onDelete: { todo in
                                service.deleteTodo(todo)
                            },
                            onEdit: { todo in
                                selectedTodo = todo
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
            .navigationTitle("待办事项")
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
                AddTodoView(service: service)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(item: $selectedTodo) { todo in
                EditTodoView(service: service, todo: todo)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
        }
    }
}

// MARK: - 进度卡片
struct TodoProgressCard: View {
    let progress: TodoProgress
    
    var body: some View {
        GradientCardView(
            colors: [
                Color(hex: "11998e"),
                Color(hex: "38ef7d")
            ],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            HStack(spacing: 24) {
                // 圆形进度
                CircularProgressView(
                    progress: progress.percentage,
                    size: 100,
                    lineWidth: 10,
                    foregroundColor: .white,
                    backgroundColor: Color.white.opacity(0.2)
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日进度")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        StatItem(value: progress.completed, label: "已完成", color: .white)
                        StatItem(value: progress.remaining, label: "待完成", color: .white)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(color.opacity(0.8))
        }
    }
}

// MARK: - 快速筛选栏
struct QuickFilterBar: View {
    @Binding var selectedFilter: TodoFilter
    let service: TodoService
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TodoFilter.allCases) { filter in
                    let count = getCount(for: filter)
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        count: count,
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
    }
    
    private func getCount(for filter: TodoFilter) -> Int {
        service.filteredTodos(filter: filter).count
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? color
                    : color.opacity(0.1)
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - 待办列表
struct TodoListSection: View {
    let todos: [TodoItem]
    let onToggle: (TodoItem) -> Void
    let onDelete: (TodoItem) -> Void
    let onEdit: (TodoItem) -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("任务列表")
                        .font(.headline)
                    Spacer()
                    Text("\(todos.count) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if todos.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "没有任务",
                        message: "当前筛选条件下没有待办事项",
                        accentColor: .green
                    )
                    .frame(height: 180)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                            TodoRow(todo: todo)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onEdit(todo)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        onDelete(todo)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        onToggle(todo)
                                    } label: {
                                        Label(todo.isCompleted ? "取消完成" : "完成", 
                                              systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                    }
                                    .tint(todo.isCompleted ? .orange : .green)
                                }
                            
                            if index < todos.count - 1 {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TodoRow: View {
    let todo: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            // 完成状态
            ZStack(alignment: .center) {
                Circle()
                    .stroke(todo.isCompleted ? Color.green : Color(hex: todo.priority.color), lineWidth: 2)
                    .frame(width: 28, height: 28)

                if todo.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .frame(width: 28, height: 28)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    // 优先级
                    HStack(spacing: 2) {
                        Image(systemName: todo.priority.icon)
                            .font(.system(size: 10))
                        Text(todo.priority.title)
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: todo.priority.color))
                    
                    // 截止日期
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(todo.isOverdue ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // 逾期标记
            if todo.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 12)
        .opacity(todo.isCompleted ? 0.6 : 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 添加/编辑视图
struct AddTodoView: View {
    @ObservedObject var service: TodoService
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date? = nil
    @State private var selectedPriority: TodoPriority = .medium
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    Toggle("设置截止日期", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("截止日期", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ))
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $selectedPriority) {
                        ForEach(TodoPriority.allCases) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.title)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTodo() {
        let todo = TodoItem(
            title: title,
            notes: notes,
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority
        )
        
        service.addTodo(todo)
        dismiss()
    }
}

struct EditTodoView: View {
    @ObservedObject var service: TodoService
    let todo: TodoItem
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date?
    @State private var selectedPriority: TodoPriority
    @State private var hasDueDate: Bool
    @State private var isCompleted: Bool
    
    init(service: TodoService, todo: TodoItem) {
        self.service = service
        self.todo = todo
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes)
        _dueDate = State(initialValue: todo.dueDate)
        _selectedPriority = State(initialValue: todo.priority)
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _isCompleted = State(initialValue: todo.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    Toggle("设置截止日期", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("截止日期", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ))
                    }
                    
                    Toggle("已完成", isOn: $isCompleted)
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $selectedPriority) {
                        ForEach(TodoPriority.allCases) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.title)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(role: .destructive) {
                        service.deleteTodo(todo)
                        dismiss()
                    } label: {
                        Text("删除任务")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func updateTodo() {
        var updatedTodo = todo
        updatedTodo.title = title
        updatedTodo.notes = notes
        updatedTodo.dueDate = hasDueDate ? dueDate : nil
        updatedTodo.priority = selectedPriority
        updatedTodo.isCompleted = isCompleted
        
        service.updateTodo(updatedTodo)
        dismiss()
    }
}

struct TodoView_Previews: PreviewProvider {
    static var previews: some View {
        TodoView()
    }
}
