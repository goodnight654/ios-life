//
//  AccountView.swift
//  LifeAssistant
//

import SwiftUI
import Charts

struct AccountView: View {
    @StateObject private var service = AccountService()
    @State private var showingAddSheet = false
    @State private var selectedDateRange: DateRange = .month
    @State private var selectedRecord: AccountRecord?
    @State private var showingMonthlySummary = false
    @State private var showingYearlySummary = false
    @State private var selectedYear: Int?

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // 统计卡片
                        StatisticsCard(statistics: service.getStatistics(for: selectedDateRange))
                            .id("top")

                        // 时间范围选择器
                        DateRangePicker(selectedRange: $selectedDateRange)
                            .padding(.horizontal)

                        // 汇总入口
                        SummaryButtons(
                            onMonthlyTap: { showingMonthlySummary = true },
                            onYearlyTap: {
                                selectedYear = Calendar.current.component(.year, from: Date())
                                showingYearlySummary = true
                            }
                        )
                        .padding(.horizontal)

                        // 分类统计
                        CategoryBreakdownView(statistics: service.getStatistics(for: selectedDateRange))
                            .padding(.horizontal)

                        // 最近记录
                        RecentRecordsSection(
                            records: service.records.prefix(10).map { $0 },
                            onDelete: { record in
                                service.deleteRecord(record)
                            },
                            onEdit: { record in
                                selectedRecord = record
                            }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    // 确保滚动到顶部
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .navigationTitle("记账")
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
                AddAccountRecordView(service: service)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(item: $selectedRecord) { record in
                EditAccountRecordView(service: service, record: record)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showingMonthlySummary) {
                MonthlySummaryView(service: service)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showingYearlySummary) {
                if let year = selectedYear {
                    YearlySummaryView(service: service, year: year)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(20)
                }
            }
        }
    }
}

// MARK: - 统计卡片
struct StatisticsCard: View {
    let statistics: AccountStatistics
    
    var body: some View {
        GradientCardView(
            colors: [
                Color(hex: "667eea"),
                Color(hex: "764ba2")
            ],
            cornerRadius: 24,
            shadowRadius: 12
        ) {
            VStack(spacing: 20) {
                // 余额
                VStack(spacing: 4) {
                    Text("当前结余")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(String(format: "¥%.2f", statistics.balance))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 收入和支出
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(Color(hex: "4ade80"))
                            Text("收入")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Text(String(format: "¥%.2f", statistics.totalIncome))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "4ade80"))
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(Color(hex: "f87171"))
                            Text("支出")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Text(String(format: "¥%.2f", statistics.totalExpense))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "f87171"))
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
}

// MARK: - 时间范围选择器
struct DateRangePicker: View {
    @Binding var selectedRange: DateRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DateRange.allCases) { range in
                    Button(action: { selectedRange = range }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedRange == range ? .semibold : .medium)
                            .foregroundColor(selectedRange == range ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedRange == range
                                    ? Color.blue
                                    : Color.gray.opacity(0.15)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

// MARK: - 分类统计
struct CategoryBreakdownView: View {
    let statistics: AccountStatistics
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("分类统计")
                    .font(.headline)
                
                if statistics.categoryBreakdown.isEmpty {
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(Array(statistics.categoryBreakdown.sorted { $0.value > $1.value }.prefix(5)), id: \.key) { category, amount in
                        CategoryRow(category: category, amount: amount, total: statistics.totalExpense + statistics.totalIncome)
                    }
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: AccountCategory
    let amount: Double
    let total: Double

    var percentage: Double {
        total > 0 ? amount / total : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color(hex: category.color).opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: category.color))
            }
            .frame(width: 36, height: 36)
            
            // 名称和进度
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "¥%.2f", amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressBar(
                    progress: percentage,
                    height: 6,
                    backgroundColor: Color.gray.opacity(0.1),
                    foregroundColor: Color(hex: category.color)
                )
            }
        }
    }
}

// MARK: - 最近记录
struct RecentRecordsSection: View {
    let records: [AccountRecord]
    let onDelete: (AccountRecord) -> Void
    let onEdit: (AccountRecord) -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("最近记录")
                        .font(.headline)
                    Spacer()
                    Text("\(records.count) 笔")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if records.isEmpty {
                    EmptyStateView(
                        icon: "dollarsign.circle",
                        title: "暂无记录",
                        message: "点击右上角添加您的第一笔记录",
                        accentColor: .blue
                    )
                    .frame(height: 200)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(records) { record in
                            AccountRecordRow(record: record)
                                .onTapGesture {
                                    onEdit(record)
                                }
                                .contextMenu {
                                    Button(action: { onEdit(record) }) {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    Button(role: .destructive, action: { onDelete(record) }) {
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

struct AccountRecordRow: View {
    let record: AccountRecord

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color(hex: record.category.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: record.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: record.category.color))
            }
            .frame(width: 44, height: 44)
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(formattedDate(record.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 金额
            Text((record.isExpense ? "-" : "+") + String(format: "¥%.2f", record.amount))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(record.isExpense ? Color(hex: "ef4444") : Color(hex: "22c55e"))
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 添加/编辑视图
struct AddAccountRecordView: View {
    @ObservedObject var service: AccountService
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    @State private var selectedCategory: AccountCategory = .food
    @State private var note = ""
    @State private var isExpense = true
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    // 收支切换
                    Picker("类型", selection: $isExpense) {
                        Text("支出").tag(true)
                        Text("收入").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // 金额
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("金额", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                    
                    // 日期
                    DatePicker("日期", selection: $date)
                }
                
                Section(header: Text("分类")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                        ForEach(isExpense ? AccountCategory.allCases.filter(\.isExpense) : AccountCategory.allCases.filter({ !$0.isExpense })) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func saveRecord() {
        guard let amountValue = Double(amount) else { return }
        
        let record = AccountRecord(
            amount: amountValue,
            category: selectedCategory,
            note: note,
            date: date,
            isExpense: isExpense
        )
        
        service.addRecord(record)
        dismiss()
    }
}

struct EditAccountRecordView: View {
    @ObservedObject var service: AccountService
    let record: AccountRecord
    @Environment(\.dismiss) var dismiss
    
    @State private var amount: String
    @State private var selectedCategory: AccountCategory
    @State private var note: String
    @State private var isExpense: Bool
    @State private var date: Date
    
    init(service: AccountService, record: AccountRecord) {
        self.service = service
        self.record = record
        _amount = State(initialValue: String(format: "%.2f", record.amount))
        _selectedCategory = State(initialValue: record.category)
        _note = State(initialValue: record.note)
        _isExpense = State(initialValue: record.isExpense)
        _date = State(initialValue: record.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    Picker("类型", selection: $isExpense) {
                        Text("支出").tag(true)
                        Text("收入").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("金额", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                    
                    DatePicker("日期", selection: $date)
                }
                
                Section(header: Text("分类")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                        ForEach(isExpense ? AccountCategory.allCases.filter(\.isExpense) : AccountCategory.allCases.filter({ !$0.isExpense })) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                
                Section {
                    Button(role: .destructive) {
                        service.deleteRecord(record)
                        dismiss()
                    } label: {
                        Text("删除记录")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateRecord()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func updateRecord() {
        guard let amountValue = Double(amount) else { return }
        
        var updatedRecord = record
        updatedRecord.amount = amountValue
        updatedRecord.category = selectedCategory
        updatedRecord.note = note
        updatedRecord.isExpense = isExpense
        updatedRecord.date = date
        
        service.updateRecord(updatedRecord)
        dismiss()
    }
}

struct CategoryButton: View {
    let category: AccountCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(isSelected ? Color(hex: category.color) : Color(hex: category.color).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : Color(hex: category.color))
                }
                .frame(width: 50, height: 50)

                Text(category.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color(hex: category.color) : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(minWidth: 60)
        }
    }
}

// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 汇总按钮
struct SummaryButtons: View {
    let onMonthlyTap: () -> Void
    let onYearlyTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onMonthlyTap) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("月度汇总")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("查看本月收支详情")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)

            Button(action: onYearlyTap) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("年度汇总")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("查看年度统计")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - 月度汇总视图
struct MonthlySummaryView: View {
    let service: AccountService
    @Environment(\.dismiss) var dismiss
    @State private var selectedMonth = Date()

    private var summary: MonthlySummary {
        service.getMonthlySummary(for: selectedMonth)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 月份选择器
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        Text(summary.monthString)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    // 总览卡片
                    MonthlyOverviewCard(summary: summary)

                    // 收支对比
                    IncomeExpenseCard(income: summary.totalIncome, expense: summary.totalExpense)

                    // 分类明细
                    if !summary.categoryBreakdown.isEmpty {
                        CategoryBreakdownCard(breakdown: summary.categoryBreakdown, total: summary.totalExpense)
                    }

                    // 统计信息
                    StatisticsInfoCard(recordCount: summary.recordCount)
                }
                .padding(.vertical)
            }
            .navigationTitle("月度汇总")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

struct MonthlyOverviewCard: View {
    let summary: MonthlySummary

    var body: some View {
        GradientCardView(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            cornerRadius: 20,
            shadowRadius: 8
        ) {
            VStack(spacing: 16) {
                Text("本月结余")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(String(format: "¥%.2f", summary.balance))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("收入")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "¥%.2f", summary.totalIncome))
                            .font(.headline)
                            .foregroundColor(Color(hex: "4ade80"))
                    }

                    VStack(spacing: 4) {
                        Text("支出")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "¥%.2f", summary.totalExpense))
                            .font(.headline)
                            .foregroundColor(Color(hex: "f87171"))
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal)
    }
}

struct IncomeExpenseCard: View {
    let income: Double
    let expense: Double

    var total: Double { income + expense }
    var incomePercent: Double { total > 0 ? income / total : 0 }
    var expensePercent: Double { total > 0 ? expense / total : 0 }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("收支对比")
                    .font(.headline)

                HStack(spacing: 4) {
                    // 收入条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: max(20, CGFloat(incomePercent) * 200), height: 24)

                    // 支出条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: max(20, CGFloat(expensePercent) * 200), height: 24)
                }

                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("收入 \(String(format: "%.1f%%", incomePercent * 100))")
                            .font(.caption)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("支出 \(String(format: "%.1f%%", expensePercent * 100))")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct CategoryBreakdownCard: View {
    let breakdown: [AccountCategory: Double]
    let total: Double

    var sortedCategories: [(AccountCategory, Double)] {
        breakdown.sorted { $0.value > $1.value }
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("支出分类")
                    .font(.headline)

                ForEach(sortedCategories.prefix(6), id: \.0.rawValue) { category, amount in
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: category.color))
                            .frame(width: 24)

                        Text(category.rawValue)
                            .font(.subheadline)

                        Spacer()

                        Text(String(format: "¥%.2f", amount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct StatisticsInfoCard: View {
    let recordCount: Int

    var body: some View {
        CardView {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("共 \(recordCount) 笔记录")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 年度汇总视图
struct YearlySummaryView: View {
    let service: AccountService
    let year: Int
    @Environment(\.dismiss) var dismiss

    private var summary: YearlySummary {
        service.getYearlySummary(for: year)
    }

    private var availableYears: [Int] {
        service.getAvailableYears()
    }

    @State private var selectedYear: Int

    init(service: AccountService, year: Int) {
        self.service = service
        self.year = year
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 年份选择器
                    Picker("选择年份", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // 年度总览
                    YearlyOverviewCard(summary: service.getYearlySummary(for: selectedYear))

                    // 月度趋势
                    MonthlyTrendCard(monthlyData: service.getYearlySummary(for: selectedYear).monthlyData)

                    // 支出分类
                    if !service.getYearlySummary(for: selectedYear).categoryBreakdown.isEmpty {
                        CategoryBreakdownCard(
                            breakdown: service.getYearlySummary(for: selectedYear).categoryBreakdown,
                            total: service.getYearlySummary(for: selectedYear).totalExpense
                        )
                    }

                    // 统计信息
                    YearlyStatisticsCard(summary: service.getYearlySummary(for: selectedYear))
                }
                .padding(.vertical)
            }
            .navigationTitle("年度汇总")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct YearlyOverviewCard: View {
    let summary: YearlySummary

    var body: some View {
        GradientCardView(
            colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
            cornerRadius: 20,
            shadowRadius: 8
        ) {
            VStack(spacing: 16) {
                Text("\(summary.year)年度总结")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(String(format: "¥%.2f", summary.balance))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("总收入")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "¥%.2f", summary.totalIncome))
                            .font(.headline)
                            .foregroundColor(Color(hex: "4ade80"))
                    }

                    VStack(spacing: 4) {
                        Text("总支出")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "¥%.2f", summary.totalExpense))
                            .font(.headline)
                            .foregroundColor(Color(hex: "f87171"))
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal)
    }
}

struct MonthlyTrendCard: View {
    let monthlyData: [Int: (income: Double, expense: Double)]

    var sortedMonths: [(Int, (income: Double, expense: Double))] {
        monthlyData.sorted { $0.key < $1.key }
    }

    var maxExpense: Double {
        monthlyData.values.map { $0.expense }.max() ?? 1
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("月度支出趋势")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...12, id: \.self) { month in
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 24, height: CGFloat((monthlyData[month]?.expense ?? 0) / maxExpense) * 100)

                                Text("\(month)月")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                HStack {
                    Text("月均支出:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let avgExpense = monthlyData.filter { $0.value.expense > 0 }.values.map { $0.expense }.reduce(0, +) / Double(max(1, monthlyData.filter { $0.value.expense > 0 }.count))
                    Text(String(format: "¥%.2f", avgExpense))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct YearlyStatisticsCard: View {
    let summary: YearlySummary

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("全年共 \(summary.recordCount) 笔记录")
                        .font(.subheadline)
                    Spacer()
                }

                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    Text("月均支出: \(String(format: "¥%.2f", summary.averageMonthlyExpense))")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
