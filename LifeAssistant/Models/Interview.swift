//
//  Interview.swift
//  LifeAssistant
//

import Foundation
import CoreData

enum InterviewStatus: Int16, CaseIterable, Identifiable {
    case applied = 0
    case screening = 1
    case interview = 2
    case offer = 3
    case rejected = 4
    case accepted = 5
    
    var id: Int16 { rawValue }
    
    var title: String {
        switch self {
        case .applied: return "已投递"
        case .screening: return "笔试中"
        case .interview: return "面试中"
        case .offer: return "已Offer"
        case .rejected: return "已拒绝"
        case .accepted: return "已接受"
        }
    }
    
    var color: String {
        switch self {
        case .applied: return "74B9FF"
        case .screening: return "A29BFE"
        case .interview: return "FD79A8"
        case .offer: return "55E6C1"
        case .rejected: return "636E72"
        case .accepted: return "00B894"
        }
    }
    
    var icon: String {
        switch self {
        case .applied: return "paperplane.fill"
        case .screening: return "pencil.circle.fill"
        case .interview: return "person.2.fill"
        case .offer: return "envelope.fill"
        case .rejected: return "xmark.circle.fill"
        case .accepted: return "checkmark.circle.fill"
        }
    }
    
    var isActive: Bool {
        self != .rejected && self != .accepted
    }
}

struct Interview: Identifiable {
    let id: UUID
    var company: String
    var position: String
    var ddl: Date
    var status: InterviewStatus
    var notes: String
    var location: String
    var salary: String
    var createdAt: Date
    
    init(id: UUID = UUID(), company: String, position: String, ddl: Date, status: InterviewStatus = .applied, notes: String = "", location: String = "", salary: String = "", createdAt: Date = Date()) {
        self.id = id
        self.company = company
        self.position = position
        self.ddl = ddl
        self.status = status
        self.notes = notes
        self.location = location
        self.salary = salary
        self.createdAt = createdAt
    }
    
    init(from entity: InterviewEntity) {
        self.id = entity.id ?? UUID()
        self.company = entity.company ?? ""
        self.position = entity.position ?? ""
        self.ddl = entity.ddl ?? Date()
        self.status = InterviewStatus(rawValue: entity.status) ?? .applied
        self.notes = entity.notes ?? ""
        self.location = entity.location ?? ""
        self.salary = entity.salary ?? ""
        self.createdAt = entity.createdAt ?? Date()
    }
    
    var daysUntilDDL: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: ddl))
        return components.day ?? 0
    }
    
    var urgencyLevel: UrgencyLevel {
        let days = daysUntilDDL
        if days < 0 { return .overdue }
        if days <= 3 { return .urgent }
        if days <= 7 { return .soon }
        return .normal
    }
}

enum UrgencyLevel: Int {
    case overdue = -1
    case urgent = 0
    case soon = 1
    case normal = 2
    
    var color: String {
        switch self {
        case .overdue: return "FF4757"
        case .urgent: return "FFA502"
        case .soon: return "2ED573"
        case .normal: return "747D8C"
        }
    }
    
    var description: String {
        switch self {
        case .overdue: return "已过期"
        case .urgent: return "紧急"
        case .soon: return "即将到期"
        case .normal: return "正常"
        }
    }
}
