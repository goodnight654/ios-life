//
//  AccountService.swift
//  LifeAssistant
//

import Foundation
import CoreData
import SwiftUI

class AccountService: ObservableObject {
    @Published var records: [AccountRecord] = []

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchRecords()
    }

    // MARK: - CRUD Operations

    func fetchRecords() {
        let request: NSFetchRequest<AccountRecordEntity> = AccountRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AccountRecordEntity.date, ascending: false)]

        do {
            let entities = try viewContext.fetch(request)
            records = entities.map { AccountRecord(from: $0) }
        } catch {
            print("Error fetching records: \(error)")
        }
    }

    func addRecord(_ record: AccountRecord) {
        let entity = AccountRecordEntity(context: viewContext)
        entity.id = record.id
        entity.amount = record.amount
        entity.category = record.category.rawValue
        entity.note = record.note
        entity.date = record.date
        entity.isExpense = record.isExpense
        entity.createdAt = record.createdAt

        save()
        fetchRecords()
    }

    func updateRecord(_ record: AccountRecord) {
        let request: NSFetchRequest<AccountRecordEntity> = AccountRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.amount = record.amount
                entity.category = record.category.rawValue
                entity.note = record.note
                entity.date = record.date
                entity.isExpense = record.isExpense
                save()
                fetchRecords()
            }
        } catch {
            print("Error updating record: \(error)")
        }
    }

    func deleteRecord(_ record: AccountRecord) {
        let request: NSFetchRequest<AccountRecordEntity> = AccountRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                save()
                fetchRecords()
            }
        } catch {
            print("Error deleting record: \(error)")
        }
    }

    // MARK: - Statistics

    func getStatistics(for dateRange: DateRange) -> AccountStatistics {
        let calendar = Calendar.current
        let filteredRecords: [AccountRecord]

        switch dateRange {
        case .today:
            filteredRecords = records.filter { calendar.isDateInToday($0.date) }
        case .week:
            filteredRecords = records.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .month:
            filteredRecords = records.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .year:
            filteredRecords = records.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        case .all:
            filteredRecords = records
        }

        let income = filteredRecords.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
        let expense = filteredRecords.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }

        var categoryBreakdown: [AccountCategory: Double] = [:]
        for record in filteredRecords {
            categoryBreakdown[record.category, default: 0] += record.amount
        }

        var dailyData: [Date: Double] = [:]
        for record in filteredRecords {
            let day = calendar.startOfDay(for: record.date)
            let amount = record.isExpense ? -record.amount : record.amount
            dailyData[day, default: 0] += amount
        }

        return AccountStatistics(
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense,
            categoryBreakdown: categoryBreakdown,
            dailyData: dailyData
        )
    }

    // MARK: - 月度汇总

    func getMonthlySummary(for month: Date) -> MonthlySummary {
        let calendar = Calendar.current
        let filteredRecords = records.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }

        let income = filteredRecords.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
        let expense = filteredRecords.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }

        var categoryBreakdown: [AccountCategory: Double] = [:]
        for record in filteredRecords where record.isExpense {
            categoryBreakdown[record.category, default: 0] += record.amount
        }

        // 按周分组
        var weeklyData: [Int: (income: Double, expense: Double)] = [:]
        for record in filteredRecords {
            let weekOfYear = calendar.component(.weekOfYear, from: record.date)
            if record.isExpense {
                weeklyData[weekOfYear, default: (0, 0)].expense += record.amount
            } else {
                weeklyData[weekOfYear, default: (0, 0)].income += record.amount
            }
        }

        return MonthlySummary(
            month: month,
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense,
            categoryBreakdown: categoryBreakdown,
            weeklyData: weeklyData,
            recordCount: filteredRecords.count
        )
    }

    // MARK: - 年度汇总

    func getYearlySummary(for year: Int) -> YearlySummary {
        let calendar = Calendar.current
        let filteredRecords = records.filter {
            calendar.component(.year, from: $0.date) == year
        }

        let income = filteredRecords.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount }
        let expense = filteredRecords.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }

        // 按月分组
        var monthlyData: [Int: (income: Double, expense: Double)] = [:]
        for record in filteredRecords {
            let month = calendar.component(.month, from: record.date)
            if record.isExpense {
                monthlyData[month, default: (0, 0)].expense += record.amount
            } else {
                monthlyData[month, default: (0, 0)].income += record.amount
            }
        }

        // 分类统计
        var categoryBreakdown: [AccountCategory: Double] = [:]
        for record in filteredRecords where record.isExpense {
            categoryBreakdown[record.category, default: 0] += record.amount
        }

        return YearlySummary(
            year: year,
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense,
            monthlyData: monthlyData,
            categoryBreakdown: categoryBreakdown,
            recordCount: filteredRecords.count
        )
    }

    // MARK: - 获取可用年份

    func getAvailableYears() -> [Int] {
        let calendar = Calendar.current
        let years = Set(records.map { calendar.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    // MARK: - Helper

    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - 数据模型

enum DateRange: String, CaseIterable, Identifiable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
    case year = "本年"
    case all = "全部"

    var id: String { rawValue }
}

// 月度汇总数据
struct MonthlySummary {
    let month: Date
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let categoryBreakdown: [AccountCategory: Double]
    let weeklyData: [Int: (income: Double, expense: Double)]
    let recordCount: Int

    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: month)
    }
}

// 年度汇总数据
struct YearlySummary {
    let year: Int
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let monthlyData: [Int: (income: Double, expense: Double)]
    let categoryBreakdown: [AccountCategory: Double]
    let recordCount: Int

    var averageMonthlyExpense: Double {
        let monthsWithExpenses = monthlyData.filter { $0.value.expense > 0 }.count
        return monthsWithExpenses > 0 ? totalExpense / Double(monthsWithExpenses) : 0
    }
}