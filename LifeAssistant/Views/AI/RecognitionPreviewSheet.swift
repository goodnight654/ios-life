//
//  RecognitionPreviewSheet.swift
//  LifeAssistant
//

import SwiftUI

// MARK: - 识别预览编辑弹窗
struct RecognitionPreviewSheet: View {
    let result: AIRecognitionResult
    let image: UIImage?
    let accountService: AccountService
    let todoService: TodoService
    let onSave: (String) -> Void

    @Environment(\.dismiss) var dismiss

    // 记账编辑状态
    @State private var amount: String = ""
    @State private var selectedCategory: AccountCategory = .other
    @State private var note: String = ""
    @State private var merchant: String = ""
    @State private var isExpense: Bool = true
    @State private var date = Date()

    // 待办编辑状态
    @State private var todoTitle: String = ""
    @State private var todoNotes: String = ""
    @State private var todoDueDate: Date?
    @State private var todoPriority: TodoPriority = .medium
    @State private var hasDueDate: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片预览
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    // 根据类型显示不同编辑表单
                    if result.type == .receipt {
                        AccountEditForm(
                            amount: $amount,
                            selectedCategory: $selectedCategory,
                            note: $note,
                            merchant: $merchant,
                            isExpense: $isExpense,
                            date: $date
                        )
                    } else if result.type == .todo {
                        TodoEditForm(
                            title: $todoTitle,
                            notes: $todoNotes,
                            dueDate: $todoDueDate,
                            priority: $todoPriority,
                            hasDueDate: $hasDueDate
                        )
                    } else {
                        UnknownTypeView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(result.type == .receipt ? "记账详情" : result.type == .todo ? "待办详情" : "识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveData()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    private func loadData() {
        guard let data = result.extractedData else { return }

        // 加载记账数据
        if let amt = data.amount {
            amount = String(format: "%.2f", amt)
        }
        if let cat = data.category {
            selectedCategory = cat
        }
        if let merch = data.merchant {
            merchant = merch
            note = merch
        }
        if data.title != nil {
            note = data.title ?? ""
        }

        // 加载待办数据
        if let title = data.title {
            todoTitle = title
        }
        if let notes = data.title {
            todoNotes = notes
        }
        if let dueDate = data.dueDate {
            todoDueDate = dueDate
            hasDueDate = true
        }
    }

    private func saveData() {
        if result.type == .receipt {
            saveAccount()
        } else if result.type == .todo {
            saveTodo()
        }
    }

    private func saveAccount() {
        guard let amt = Double(amount), amt > 0 else { return }

        let record = AccountRecord(
            amount: amt,
            category: selectedCategory,
            note: note.isEmpty ? merchant : note,
            date: date,
            isExpense: isExpense
        )

        accountService.addRecord(record)
        onSave("已添加记账: ¥\(String(format: "%.2f", amt))")
    }

    private func saveTodo() {
        guard !todoTitle.isEmpty else { return }

        let todo = TodoItem(
            title: todoTitle,
            notes: todoNotes,
            dueDate: hasDueDate ? todoDueDate : nil,
            priority: todoPriority
        )

        todoService.addTodo(todo)
        onSave("已添加待办: \(todoTitle)")
    }
}

// MARK: - 记账编辑表单
struct AccountEditForm: View {
    @Binding var amount: String
    @Binding var selectedCategory: AccountCategory
    @Binding var note: String
    @Binding var merchant: String
    @Binding var isExpense: Bool
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 20) {
            // 类型切换
            Picker("类型", selection: $isExpense) {
                Text("支出").tag(true)
                Text("收入").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // 金额
            VStack(alignment: .leading, spacing: 8) {
                Text("金额")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("¥")
                        .font(.title)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amount)
                        .font(.title)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // 分类选择
            VStack(alignment: .leading, spacing: 8) {
                Text("分类")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(AccountCategory.allCases.filter { $0.isExpense == isExpense }) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)

            // 商家
            VStack(alignment: .leading, spacing: 8) {
                Text("商家")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("商家名称", text: $merchant)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            // 备注
            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("添加备注", text: $note)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            // 日期
            VStack(alignment: .leading, spacing: 8) {
                Text("日期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 待办编辑表单
struct TodoEditForm: View {
    @Binding var title: String
    @Binding var notes: String
    @Binding var dueDate: Date?
    @Binding var priority: TodoPriority
    @Binding var hasDueDate: Bool

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(alignment: .leading, spacing: 8) {
                Text("标题")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("待办事项", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            // 详细说明
            VStack(alignment: .leading, spacing: 8) {
                Text("详细说明")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            // 截止日期
            VStack(alignment: .leading, spacing: 8) {
                Toggle("设置截止日期", isOn: $hasDueDate)
                    .font(.subheadline)

                if hasDueDate {
                    DatePicker("截止日期", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .padding(.horizontal)

            // 优先级
            VStack(alignment: .leading, spacing: 8) {
                Text("优先级")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    ForEach([TodoPriority.high, .medium, .low], id: \.self) { p in
                        Button(action: { priority = p }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: p.color))
                                    .frame(width: 10, height: 10)
                                Text(p.title)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(priority == p ? Color(hex: p.color).opacity(0.15) : Color(.secondarySystemBackground))
                            .cornerRadius(20)
                        }
                        .foregroundColor(priority == p ? Color(hex: p.color) : .secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 未知类型视图
struct UnknownTypeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("无法识别此图片类型")
                .font(.headline)

            Text("请尝试上传包含记账或待办信息的图片")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - 历史详情弹窗
struct HistoryDetailSheet: View {
    let record: AIRecognitionRecord
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片
                    if let image = record.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    // 类型标签
                    HStack {
                        CategoryBadge(
                            title: record.category == .receipt ? "记账" : record.category == .todo ? "待办" : "未知",
                            color: record.category == .receipt ? .green : record.category == .todo ? .blue : .gray,
                            icon: record.category == .receipt ? "dollarsign.circle" : record.category == .todo ? "checklist" : "questionmark"
                        )

                        Spacer()

                        Text(formatDate(record.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // 识别文本
                    VStack(alignment: .leading, spacing: 8) {
                        Text("识别内容")
                            .font(.headline)

                        Text(record.recognizedText)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // 时间信息
                    HStack {
                        Label("识别时间", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDateTime(record.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("识别详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}