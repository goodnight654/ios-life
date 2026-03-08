//
//  AccountRecord.swift
//  LifeAssistant
//

import Foundation
import CoreData

enum AccountCategory: String, CaseIterable, Identifiable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case housing = "住房"
    case medical = "医疗"
    case education = "教育"
    case salary = "工资"
    case investment = "投资"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .medical: return "cross.case.fill"
        case .education: return "book.fill"
        case .salary: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "FF6B6B"
        case .transport: return "4ECDC4"
        case .shopping: return "45B7D1"
        case .entertainment: return "96CEB4"
        case .housing: return "FFEAA7"
        case .medical: return "DDA0DD"
        case .education: return "98D8C8"
        case .salary: return "55E6C1"
        case .investment: return "F8B500"
        case .other: return "B2BEC3"
        }
    }
    
    var isExpense: Bool {
        switch self {
        case .salary, .investment:
            return false
        default:
            return true
        }
    }
}

struct AccountRecord: Identifiable {
    let id: UUID
    var amount: Double
    var category: AccountCategory
    var note: String
    var date: Date
    var isExpense: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), amount: Double, category: AccountCategory, note: String = "", date: Date = Date(), isExpense: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
        self.isExpense = isExpense
        self.createdAt = createdAt
    }
    
    init(from entity: AccountRecordEntity) {
        self.id = entity.id ?? UUID()
        self.amount = entity.amount
        self.category = AccountCategory(rawValue: entity.category ?? "其他") ?? .other
        self.note = entity.note ?? ""
        self.date = entity.date ?? Date()
        self.isExpense = entity.isExpense
        self.createdAt = entity.createdAt ?? Date()
    }
}

// MARK: - Statistics
struct AccountStatistics {
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let categoryBreakdown: [AccountCategory: Double]
    let dailyData: [Date: Double]
}
