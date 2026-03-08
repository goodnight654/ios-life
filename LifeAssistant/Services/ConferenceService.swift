//
//  ConferenceService.swift
//  LifeAssistant
//

import Foundation
import CoreData
import SwiftUI

class ConferenceService: ObservableObject {
    @Published var conferences: [Conference] = []
    @Published var statistics: ConferenceStatistics = ConferenceStatistics(conferences: [])
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchConferences()
    }
    
    // MARK: - CRUD Operations
    
    func fetchConferences() {
        let request: NSFetchRequest<ConferenceEntity> = ConferenceEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ConferenceEntity.ddl, ascending: true),
            NSSortDescriptor(keyPath: \ConferenceEntity.name, ascending: true)
        ]
        
        do {
            let entities = try viewContext.fetch(request)
            conferences = entities.map { Conference(from: $0) }
            statistics = ConferenceStatistics(conferences: conferences)
        } catch {
            print("Error fetching conferences: \(error)")
        }
    }
    
    func addConference(_ conference: Conference) {
        let entity = ConferenceEntity(context: viewContext)
        entity.id = conference.id
        entity.name = conference.name
        entity.type = conference.type.rawValue
        entity.category = conference.category.rawValue
        entity.ddl = conference.ddl
        entity.startDate = conference.startDate
        entity.endDate = conference.endDate
        entity.location = conference.location
        entity.website = conference.website
        entity.notes = conference.notes
        entity.createdAt = conference.createdAt
        
        save()
        fetchConferences()
    }
    
    func updateConference(_ conference: Conference) {
        let request: NSFetchRequest<ConferenceEntity> = ConferenceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conference.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.name = conference.name
                entity.type = conference.type.rawValue
                entity.category = conference.category.rawValue
                entity.ddl = conference.ddl
                entity.startDate = conference.startDate
                entity.endDate = conference.endDate
                entity.location = conference.location
                entity.website = conference.website
                entity.notes = conference.notes
                
                save()
                fetchConferences()
            }
        } catch {
            print("Error updating conference: \(error)")
        }
    }
    
    func deleteConference(_ conference: Conference) {
        let request: NSFetchRequest<ConferenceEntity> = ConferenceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conference.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                save()
                fetchConferences()
            }
        } catch {
            print("Error deleting conference: \(error)")
        }
    }
    
    // MARK: - Filtering & Sorting
    
    func filteredConferences(filter: ConferenceFilter) -> [Conference] {
        switch filter {
        case .all:
            return conferences
        case .conference:
            return conferences.filter { $0.type == .conference }
        case .journal:
            return conferences.filter { $0.type == .journal }
        case .workshop:
            return conferences.filter { $0.type == .workshop }
        case .urgent:
            return conferences.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .overdue }
        }
    }
    
    func filteredByCategory(_ category: AcademicCategory?) -> [Conference] {
        guard let category = category else { return conferences }
        return conferences.filter { $0.category == category }
    }
    
    func sortedConferences(by sortOption: ConferenceSortOption) -> [Conference] {
        switch sortOption {
        case .ddlAscending:
            return conferences.sorted {
                guard let ddl1 = $0.ddl, let ddl2 = $1.ddl else { return $0.ddl != nil }
                return ddl1 < ddl2
            }
        case .ddlDescending:
            return conferences.sorted {
                guard let ddl1 = $0.ddl, let ddl2 = $1.ddl else { return $0.ddl != nil }
                return ddl1 > ddl2
            }
        case .name:
            return conferences.sorted { $0.name < $1.name }
        case .category:
            return conferences.sorted { $0.category.rawValue < $1.category.rawValue }
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

struct ConferenceStatistics {
    let total: Int
    let conferenceCount: Int
    let journalCount: Int
    let workshopCount: Int
    let urgentCount: Int
    let categoryBreakdown: [AcademicCategory: Int]
    
    init(conferences: [Conference]) {
        self.total = conferences.count
        self.conferenceCount = conferences.filter { $0.type == .conference }.count
        self.journalCount = conferences.filter { $0.type == .journal }.count
        self.workshopCount = conferences.filter { $0.type == .workshop }.count
        self.urgentCount = conferences.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .overdue }.count
        
        var breakdown: [AcademicCategory: Int] = [:]
        for category in AcademicCategory.allCases {
            breakdown[category] = conferences.filter { $0.category == category }.count
        }
        self.categoryBreakdown = breakdown
    }
}

enum ConferenceFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case conference = "学术会议"
    case journal = "期刊投稿"
    case workshop = "研讨会"
    case urgent = "紧急"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "doc.text.fill"
        case .conference: return "person.3.fill"
        case .journal: return "newspaper.fill"
        case .workshop: return "hammer.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .conference: return .blue
        case .journal: return .green
        case .workshop: return .orange
        case .urgent: return .red
        }
    }
}

enum ConferenceSortOption: String, CaseIterable, Identifiable {
    case ddlAscending = "截止日期(近→远)"
    case ddlDescending = "截止日期(远→近)"
    case name = "名称"
    case category = "分类"
    
    var id: String { rawValue }
}
