//
//  TodoService.swift
//  LifeAssistant
//

import Foundation
import CoreData
import EventKit
import SwiftUI

class TodoService: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var progress: TodoProgress = TodoProgress(todos: [])
    
    private let viewContext: NSManagedObjectContext
    private let eventStore = EKEventStore()
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchTodos()
    }
    
    // MARK: - CRUD Operations
    
    func fetchTodos() {
        let request: NSFetchRequest<TodoItemEntity> = TodoItemEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TodoItemEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TodoItemEntity.priority, ascending: false),
            NSSortDescriptor(keyPath: \TodoItemEntity.dueDate, ascending: true)
        ]
        
        do {
            let entities = try viewContext.fetch(request)
            todos = entities.map { TodoItem(from: $0) }
            progress = TodoProgress(todos: todos)
        } catch {
            print("Error fetching todos: \(error)")
        }
    }
    
    func addTodo(_ todo: TodoItem) {
        let entity = TodoItemEntity(context: viewContext)
        entity.id = todo.id
        entity.title = todo.title
        entity.notes = todo.notes
        entity.dueDate = todo.dueDate
        entity.priority = todo.priority.rawValue
        entity.isCompleted = todo.isCompleted
        entity.createdAt = todo.createdAt
        
        // 同步到系统提醒
        if let dueDate = todo.dueDate {
            createReminder(for: todo, dueDate: dueDate) { reminderID in
                DispatchQueue.main.async {
                    entity.reminderID = reminderID
                    self.save()
                    self.fetchTodos()
                }
            }
        } else {
            save()
            fetchTodos()
        }
    }
    
    func updateTodo(_ todo: TodoItem) {
        let request: NSFetchRequest<TodoItemEntity> = TodoItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", todo.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                entity.title = todo.title
                entity.notes = todo.notes
                entity.dueDate = todo.dueDate
                entity.priority = todo.priority.rawValue
                entity.isCompleted = todo.isCompleted
                
                // 更新系统提醒
                if let dueDate = todo.dueDate {
                    updateReminder(reminderID: entity.reminderID, todo: todo, dueDate: dueDate)
                } else if entity.reminderID != nil {
                    deleteReminder(reminderID: entity.reminderID)
                    entity.reminderID = nil
                }
                
                save()
                fetchTodos()
            }
        } catch {
            print("Error updating todo: \(error)")
        }
    }
    
    func toggleComplete(_ todo: TodoItem) {
        var updatedTodo = todo
        updatedTodo.isCompleted.toggle()
        updateTodo(updatedTodo)
    }
    
    func deleteTodo(_ todo: TodoItem) {
        let request: NSFetchRequest<TodoItemEntity> = TodoItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", todo.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                // 删除系统提醒
                if let reminderID = entity.reminderID {
                    deleteReminder(reminderID: reminderID)
                }
                viewContext.delete(entity)
                save()
                fetchTodos()
            }
        } catch {
            print("Error deleting todo: \(error)")
        }
    }
    
    // MARK: - Filtering
    
    func filteredTodos(filter: TodoFilter) -> [TodoItem] {
        switch filter {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.isCompleted }
        case .completed:
            return todos.filter { $0.isCompleted }
        case .overdue:
            return todos.filter { $0.isOverdue }
        case .today:
            let calendar = Calendar.current
            return todos.filter {
                guard let dueDate = $0.dueDate else { return false }
                return calendar.isDateInToday(dueDate) && !$0.isCompleted
            }
        case .upcoming:
            let calendar = Calendar.current
            return todos.filter {
                guard let dueDate = $0.dueDate else { return false }
                return dueDate > Date() && !$0.isCompleted
            }
        }
    }
    
    // MARK: - EventKit Integration
    
    private func createReminder(for todo: TodoItem, dueDate: Date, completion: @escaping (String?) -> Void) {
        eventStore.requestFullAccessToReminders { granted, error in
            guard granted else {
                completion(nil)
                return
            }
            
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = todo.title
            reminder.notes = todo.notes
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            
            do {
                try self.eventStore.save(reminder, commit: true)
                completion(reminder.calendarItemIdentifier)
            } catch {
                print("Error creating reminder: \(error)")
                completion(nil)
            }
        }
    }
    
    private func updateReminder(reminderID: String?, todo: TodoItem, dueDate: Date) {
        guard let reminderID = reminderID,
              let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder else {
            return
        }
        
        reminder.title = todo.title
        reminder.notes = todo.notes
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        reminder.isCompleted = todo.isCompleted
        
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error updating reminder: \(error)")
        }
    }
    
    private func deleteReminder(reminderID: String?) {
        guard let reminderID = reminderID,
              let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder else {
            return
        }
        
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Error deleting reminder: \(error)")
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

enum TodoFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case active = "进行中"
    case completed = "已完成"
    case overdue = "已逾期"
    case today = "今天"
    case upcoming = "即将到期"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .today: return "calendar"
        case .upcoming: return "calendar.badge.clock"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .active: return .blue
        case .completed: return .green
        case .overdue: return .red
        case .today: return .orange
        case .upcoming: return .purple
        }
    }
}
