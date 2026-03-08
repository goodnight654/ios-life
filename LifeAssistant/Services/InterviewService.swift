//
//  InterviewService.swift
//  LifeAssistant
//

import Foundation
import CoreData
import SwiftUI

class InterviewService: ObservableObject {
    @Published var interviews: [Interview] = []
    @Published var statistics: InterviewStatistics = InterviewStatistics(interviews: [])
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchInterviews()
    }
    
    // MARK: - CRUD Operations
    
    func fetchInterviews() {
        let request: NSFetchRequest<InterviewEntity> = InterviewEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \InterviewEntity.ddl, ascending: true),
            NSSortDescriptor(keyPath: \InterviewEntity.status, ascending: true)
        ]
        
        do {
            let entities = try viewContext.fetch(request)
            interviews = entities.map { Interview(from: $0) }
            statistics = InterviewStatistics(interviews: interviews)
        } catch {
            print("Error fetching interviews: \(error)")
        }
    }
    
    func addInterview(_ interview: Interview) {
        let entity = InterviewEntity(context: viewContext)
        entity.id = interview.id
        entity.company = interview.company
        entity.position = interview.position
        entity.ddl = interview.ddl
        entity.status = interview.status.rawValue
        entity.notes = interview.notes
        entity.location = interview.location
        entity.salary = interview.salary
        entity.createdAt = interview.createdAt
        
        save()
        fetchInterviews()
    }
    
    func updateInterview(_ interview: Interview) {
        let request: NSFetchRequest<InterviewEntity> = InterviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", interview.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.company = interview.company
                entity.position = interview.position
                entity.ddl = interview.ddl
                entity.status = interview.status.rawValue
                entity.notes = interview.notes
                entity.location = interview.location
                entity.salary = interview.salary
                
                save()
                fetchInterviews()
            }
        } catch {
            print("Error updating interview: \(error)")
        }
    }
    
    func deleteInterview(_ interview: Interview) {
        let request: NSFetchRequest<InterviewEntity> = InterviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", interview.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                save()
                fetchInterviews()
            }
        } catch {
            print("Error deleting interview: \(error)")
        }
    }
    
    func updateStatus(for interview: Interview, to status: InterviewStatus) {
        var updated = interview
        updated.status = status
        updateInterview(updated)
    }
    
    // MARK: - Filtering & Sorting
    
    func filteredInterviews(filter: InterviewFilter) -> [Interview] {
        switch filter {
        case .all:
            return interviews
        case .active:
            return interviews.filter { $0.status.isActive }
        case .completed:
            return interviews.filter { !$0.status.isActive }
        case .urgent:
            return interviews.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .overdue }
        }
    }
    
    func sortedInterviews(by sortOption: InterviewSortOption) -> [Interview] {
        switch sortOption {
        case .ddlAscending:
            return interviews.sorted { $0.ddl < $1.ddl }
        case .ddlDescending:
            return interviews.sorted { $0.ddl > $1.ddl }
        case .status:
            return interviews.sorted { $0.status.rawValue < $1.status.rawValue }
        case .company:
            return interviews.sorted { $0.company < $1.company }
        }
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

// MARK: - Statistics

struct InterviewStatistics {
    let total: Int
    let active: Int
    let offerCount: Int
    let rejectedCount: Int
    let statusBreakdown: [InterviewStatus: Int]
    let urgentCount: Int
    
    init(interviews: [Interview]) {
        self.total = interviews.count
        self.active = interviews.filter { $0.status.isActive }.count
        self.offerCount = interviews.filter { $0.status == .offer || $0.status == .accepted }.count
        self.rejectedCount = interviews.filter { $0.status == .rejected }.count
        self.urgentCount = interviews.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .overdue }.count
        
        var breakdown: [InterviewStatus: Int] = [:]
        for status in InterviewStatus.allCases {
            breakdown[status] = interviews.filter { $0.status == status }.count
        }
        self.statusBreakdown = breakdown
    }
    
    var successRate: Double {
        let finished = offerCount + rejectedCount
        return finished > 0 ? Double(offerCount) / Double(finished) : 0
    }
}

enum InterviewFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case active = "进行中"
    case completed = "已结束"
    case urgent = "紧急"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "briefcase.fill"
        case .active: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .active: return .blue
        case .completed: return .green
        case .urgent: return .red
        }
    }
}

enum InterviewSortOption: String, CaseIterable, Identifiable {
    case ddlAscending = "截止日期(近→远)"
    case ddlDescending = "截止日期(远→近)"
    case status = "状态"
    case company = "公司名"
    
    var id: String { rawValue }
}
