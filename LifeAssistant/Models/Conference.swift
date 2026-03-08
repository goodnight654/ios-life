//
//  Conference.swift
//  LifeAssistant
//

import Foundation
import CoreData

enum ConferenceType: Int16, CaseIterable, Identifiable {
    case conference = 0
    case journal = 1
    case workshop = 2
    
    var id: Int16 { rawValue }
    
    var title: String {
        switch self {
        case .conference: return "学术会议"
        case .journal: return "期刊投稿"
        case .workshop: return "研讨会"
        }
    }
    
    var icon: String {
        switch self {
        case .conference: return "person.3.fill"
        case .journal: return "doc.text.fill"
        case .workshop: return "hammer.fill"
        }
    }
}

enum AcademicCategory: String, CaseIterable, Identifiable {
    case ai = "人工智能"
    case ml = "机器学习"
    case cv = "计算机视觉"
    case nlp = "自然语言处理"
    case sys = "系统/网络"
    case db = "数据库"
    case sec = "安全"
    case theory = "理论"
    case other = "其他"
    
    var id: String { rawValue }
    
    var color: String {
        switch self {
        case .ai: return "FF6B6B"
        case .ml: return "4ECDC4"
        case .cv: return "45B7D1"
        case .nlp: return "96CEB4"
        case .sys: return "FFEAA7"
        case .db: return "DDA0DD"
        case .sec: return "98D8C8"
        case .theory: return "F8B500"
        case .other: return "B2BEC3"
        }
    }
}

struct Conference: Identifiable {
    let id: UUID
    var name: String
    var type: ConferenceType
    var category: AcademicCategory
    var ddl: Date?
    var startDate: Date?
    var endDate: Date?
    var location: String
    var website: String
    var notes: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, type: ConferenceType, category: AcademicCategory, ddl: Date? = nil, startDate: Date? = nil, endDate: Date? = nil, location: String = "", website: String = "", notes: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.ddl = ddl
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.website = website
        self.notes = notes
        self.createdAt = createdAt
    }
    
    init(from entity: ConferenceEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.type = ConferenceType(rawValue: entity.type) ?? .conference
        self.category = AcademicCategory(rawValue: entity.category ?? "其他") ?? .other
        self.ddl = entity.ddl
        self.startDate = entity.startDate
        self.endDate = entity.endDate
        self.location = entity.location ?? ""
        self.website = entity.website ?? ""
        self.notes = entity.notes ?? ""
        self.createdAt = entity.createdAt ?? Date()
    }
    
    var daysUntilDDL: Int? {
        guard let ddl = ddl else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: ddl))
        return components.day
    }
    
    var urgencyLevel: UrgencyLevel {
        guard let days = daysUntilDDL else { return .normal }
        if days < 0 { return .overdue }
        if days <= 7 { return .urgent }
        if days <= 30 { return .soon }
        return .normal
    }
    
    var dateRangeString: String {
        guard let start = startDate else { return "待定" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        if let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return formatter.string(from: start)
    }
}
