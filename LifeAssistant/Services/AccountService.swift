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
    
    // MARK: - Helper
    
    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

enum DateRange: String, CaseIterable, Identifiable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
    case year = "本年"
    case all = "全部"
    
    var id: String { rawValue }
}
