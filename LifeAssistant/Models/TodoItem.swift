//
//  TodoItem.swift
//  LifeAssistant
//

import Foundation
import CoreData

enum TodoPriority: Int16, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int16 { rawValue }
    
    var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "95E1D3"
        case .medium: return "F38181"
        case .high: return "AA96DA"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
}

struct TodoItem: Identifiable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var priority: TodoPriority
    var isCompleted: Bool
    var reminderID: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date? = nil, priority: TodoPriority = .medium, isCompleted: Bool = false, reminderID: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.reminderID = reminderID
        self.createdAt = createdAt
    }
    
    init(from entity: TodoItemEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? ""
        self.notes = entity.notes ?? ""
        self.dueDate = entity.dueDate
        self.priority = TodoPriority(rawValue: entity.priority) ?? .medium
        self.isCompleted = entity.isCompleted
        self.reminderID = entity.reminderID
        self.createdAt = entity.createdAt ?? Date()
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: dueDate))
        return components.day
    }
}

// MARK: - Todo Progress
struct TodoProgress {
    let total: Int
    let completed: Int
    let percentage: Double
    
    var remaining: Int { total - completed }
    
    init(todos: [TodoItem]) {
        self.total = todos.count
        self.completed = todos.filter(\.isCompleted).count
        self.percentage = total > 0 ? Double(completed) / Double(total) : 0
    }
}
