//
//  ProgressService.swift
//  LifeAssistant
//

import Foundation
import CoreData

class ProgressService: ObservableObject {
    @Published var goals: [ProgressGoal] = []

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchGoals()
    }

    // MARK: - CRUD Operations

    func fetchGoals() {
        let request: NSFetchRequest<ProgressGoalEntity> = ProgressGoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressGoalEntity.updatedAt, ascending: false)]

        do {
            let entities = try viewContext.fetch(request)
            goals = entities.map { entity in
                ProgressGoal(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    notes: entity.notes ?? "",
                    progress: entity.progress,
                    createdAt: entity.createdAt ?? Date(),
                    updatedAt: entity.updatedAt ?? Date()
                )
            }
        } catch {
            print("Error fetching goals: \(error)")
        }
    }

    func addGoal(_ goal: ProgressGoal) {
        let entity = ProgressGoalEntity(context: viewContext)
        entity.id = goal.id
        entity.title = goal.title
        entity.notes = goal.notes
        entity.progress = goal.progress
        entity.createdAt = goal.createdAt
        entity.updatedAt = goal.updatedAt

        save()
        fetchGoals()
    }

    func updateGoal(_ goal: ProgressGoal) {
        let request: NSFetchRequest<ProgressGoalEntity> = ProgressGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.title = goal.title
                entity.notes = goal.notes
                entity.progress = goal.progress
                entity.updatedAt = Date()
                save()
                fetchGoals()
            }
        } catch {
            print("Error updating goal: \(error)")
        }
    }

    func updateProgress(for goalId: UUID, progress: Double) {
        let request: NSFetchRequest<ProgressGoalEntity> = ProgressGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.progress = max(0, min(1, progress))
                entity.updatedAt = Date()
                save()
                fetchGoals()
            }
        } catch {
            print("Error updating progress: \(error)")
        }
    }

    func deleteGoal(_ goal: ProgressGoal) {
        let request: NSFetchRequest<ProgressGoalEntity> = ProgressGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                save()
                fetchGoals()
            }
        } catch {
            print("Error deleting goal: \(error)")
        }
    }

    // MARK: - Statistics

    var totalGoals: Int {
        goals.count
    }

    var completedGoals: Int {
        goals.filter { $0.isCompleted }.count
    }

    var inProgressGoals: Int {
        goals.filter { !$0.isCompleted && $0.progress > 0 }.count
    }

    var averageProgress: Double {
        guard !goals.isEmpty else { return 0 }
        return goals.reduce(0) { $0 + $1.progress } / Double(goals.count)
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