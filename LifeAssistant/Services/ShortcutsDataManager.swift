//
//  ShortcutsDataManager.swift
//  LifeAssistant
//
//  专门处理快捷指令与主App之间的数据传递
//

import Foundation
import UIKit

// MARK: - 共享数据模型

/// 待保存的记账数据
struct PendingAccountData: Codable {
    let amount: Double
    let category: String
    let note: String
    let merchant: String?
    let isExpense: Bool
    let createdAt: Date
}

/// 待保存的待办数据
struct PendingTodoData: Codable {
    let title: String
    let notes: String?
    let dueDate: Date?
    let priority: String?
    let createdAt: Date
}

/// 识别结果数据
struct RecognitionResultData: Codable {
    let type: String // "account" or "todo"
    let accountData: PendingAccountData?
    let todoData: PendingTodoData?
    let recognizedText: String
    let confidence: Double
}

// MARK: - 快捷指令数据管理器

class ShortcutsDataManager {
    static let shared = ShortcutsDataManager()

    // App Groups ID - 必须与 entitlements 文件中的配置一致
    private let appGroupIdentifier = "group.com.yourcompany.LifeAssistant"

    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    // 存储键
    private enum Keys {
        static let pendingAccountRecords = "pendingAccountRecords"
        static let pendingTodoItems = "pendingTodoItems"
        static let lastRecognitionResult = "lastRecognitionResult"
    }

    private init() {}

    // MARK: - 保存识别结果

    /// 保存记账数据
    func saveAccountData(_ data: PendingAccountData) -> Bool {
        debugLog("ShortcutsDataManager: 保存记账数据 amount=\(data.amount)")

        guard let defaults = userDefaults else {
            debugLog("❌ ShortcutsDataManager: 无法访问 UserDefaults", category: "ERROR")
            return false
        }

        // 获取现有记录
        var records = getPendingAccountRecords()
        records.append(data)

        // 保存
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            defaults.set(data, forKey: Keys.pendingAccountRecords)
            defaults.synchronize()
            debugLog("✅ ShortcutsDataManager: 记账数据已保存到 UserDefaults，共 \(records.count) 条待处理")
            return true
        } catch {
            debugLog("❌ ShortcutsDataManager: 编码失败 \(error)", category: "ERROR")
            return false
        }
    }

    /// 保存待办数据
    func saveTodoData(_ data: PendingTodoData) -> Bool {
        debugLog("ShortcutsDataManager: 保存待办数据 title=\(data.title)")

        guard let defaults = userDefaults else {
            debugLog("❌ ShortcutsDataManager: 无法访问 UserDefaults", category: "ERROR")
            return false
        }

        // 获取现有记录
        var items = getPendingTodoItems()
        items.append(data)

        // 保存
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            defaults.set(data, forKey: Keys.pendingTodoItems)
            defaults.synchronize()
            debugLog("✅ ShortcutsDataManager: 待办数据已保存到 UserDefaults，共 \(items.count) 条待处理")
            return true
        } catch {
            debugLog("❌ ShortcutsDataManager: 编码失败 \(error)", category: "ERROR")
            return false
        }
    }

    // MARK: - 获取待处理数据

    func getPendingAccountRecords() -> [PendingAccountData] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: Keys.pendingAccountRecords) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([PendingAccountData].self, from: data)
        } catch {
            debugLog("❌ ShortcutsDataManager: 解码记账数据失败 \(error)", category: "ERROR")
            return []
        }
    }

    func getPendingTodoItems() -> [PendingTodoData] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: Keys.pendingTodoItems) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([PendingTodoData].self, from: data)
        } catch {
            debugLog("❌ ShortcutsDataManager: 解码待办数据失败 \(error)", category: "ERROR")
            return []
        }
    }

    // MARK: - 清除已处理数据

    func clearPendingAccountRecords() {
        userDefaults?.removeObject(forKey: Keys.pendingAccountRecords)
        userDefaults?.synchronize()
    }

    func clearPendingTodoItems() {
        userDefaults?.removeObject(forKey: Keys.pendingTodoItems)
        userDefaults?.synchronize()
    }

    // MARK: - 直接保存到 CoreData

    @MainActor
    func saveAccountToCoreData(_ data: PendingAccountData) -> Bool {
        let context = PersistenceController.shared.container.viewContext

        let entity = AccountRecordEntity(context: context)
        entity.id = UUID()
        entity.amount = data.amount
        entity.category = data.category
        entity.note = data.note
        entity.date = Date()
        entity.isExpense = data.isExpense
        entity.createdAt = data.createdAt

        do {
            try context.save()
            debugLog("✅ ShortcutsDataManager: 记账已保存到 CoreData")
            return true
        } catch {
            debugLog("❌ ShortcutsDataManager: CoreData 保存失败 \(error)", category: "ERROR")
            return false
        }
    }

    @MainActor
    func saveTodoToCoreData(_ data: PendingTodoData) -> Bool {
        let context = PersistenceController.shared.container.viewContext

        let entity = TodoItemEntity(context: context)
        entity.id = UUID()
        entity.title = data.title
        entity.notes = data.notes ?? ""
        entity.dueDate = data.dueDate
        entity.priority = mapPriorityString(data.priority)
        entity.isCompleted = false
        entity.createdAt = data.createdAt

        do {
            try context.save()
            debugLog("✅ ShortcutsDataManager: 待办已保存到 CoreData")
            return true
        } catch {
            debugLog("❌ ShortcutsDataManager: CoreData 保存失败 \(error)", category: "ERROR")
            return false
        }
    }

    private func mapPriorityString(_ priority: String?) -> Int16 {
        switch priority {
        case "high":
            return TodoPriority.high.rawValue
        case "low":
            return TodoPriority.low.rawValue
        default:
            return TodoPriority.medium.rawValue
        }
    }
}