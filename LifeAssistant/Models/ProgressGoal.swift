//
//  ProgressGoal.swift
//  LifeAssistant
//

import Foundation

struct ProgressGoal: Identifiable {
    let id: UUID
    var title: String
    var notes: String
    var progress: Double // 0.0 - 1.0
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        progress: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.progress = max(0, min(1, progress))
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var isCompleted: Bool {
        progress >= 1.0
    }

    var statusText: String {
        if isCompleted {
            return "已完成"
        } else if progress >= 0.75 {
            return "即将完成"
        } else if progress >= 0.5 {
            return "进行中"
        } else if progress > 0 {
            return "刚开始"
        } else {
            return "未开始"
        }
    }

    var statusColor: String {
        if isCompleted {
            return "22c55e" // green
        } else if progress >= 0.75 {
            return "3b82f6" // blue
        } else if progress >= 0.5 {
            return "f59e0b" // amber
        } else if progress > 0 {
            return "6366f1" // indigo
        } else {
            return "9ca3af" // gray
        }
    }
}