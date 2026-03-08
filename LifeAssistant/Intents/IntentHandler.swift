//
//  IntentHandler.swift
//  LifeAssistant
//

import Intents
import CoreData

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is AddAccountRecordIntent {
            return AddAccountRecordIntentHandler()
        } else if intent is AddTodoIntent {
            return AddTodoIntentHandler()
        } else if intent is AddInterviewIntent {
            return AddInterviewIntentHandler()
        } else if intent is AddConferenceIntent {
            return AddConferenceIntentHandler()
        } else if intent is GetTodoListIntent {
            return GetTodoListIntentHandler()
        } else if intent is GetInterviewListIntent {
            return GetInterviewListIntentHandler()
        }
        return self
    }
}

// MARK: - 添加记账记录
class AddAccountRecordIntentHandler: NSObject, AddAccountRecordIntentHandling {
    func handle(intent: AddAccountRecordIntent, completion: @escaping (AddAccountRecordIntentResponse) -> Void) {
        guard let amount = intent.amount?.doubleValue else {
            completion(AddAccountRecordIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        let entity = AccountRecordEntity(context: context)
        entity.id = UUID()
        entity.amount = amount
        entity.category = intent.category?.identifier ?? AccountCategory.other.rawValue
        entity.note = intent.note ?? ""
        entity.date = Date()
        entity.isExpense = intent.isExpense?.boolValue ?? true
        entity.createdAt = Date()
        
        do {
            try context.save()
            let response = AddAccountRecordIntentResponse(code: .success, userActivity: nil)
            response.recordID = entity.id?.uuidString
            completion(response)
        } catch {
            completion(AddAccountRecordIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
    func resolveAmount(for intent: AddAccountRecordIntent, with completion: @escaping (INDoubleResolutionResult) -> Void) {
        if let amount = intent.amount {
            completion(.success(with: amount.doubleValue))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolveCategory(for intent: AddAccountRecordIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let category = intent.category {
            completion(.success(with: category))
        } else {
            completion(.notRequired())
        }
    }
}

// MARK: - 添加待办
class AddTodoIntentHandler: NSObject, AddTodoIntentHandling {
    func handle(intent: AddTodoIntent, completion: @escaping (AddTodoIntentResponse) -> Void) {
        guard let title = intent.title, !title.isEmpty else {
            completion(AddTodoIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        let entity = TodoItemEntity(context: context)
        entity.id = UUID()
        entity.title = title
        entity.notes = intent.notes ?? ""
        entity.dueDate = intent.dueDate
        entity.priority = intent.priority?.int16Value ?? 1
        entity.isCompleted = false
        entity.createdAt = Date()
        
        do {
            try context.save()
            let response = AddTodoIntentResponse(code: .success, userActivity: nil)
            response.todoID = entity.id?.uuidString
            completion(response)
        } catch {
            completion(AddTodoIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
    func resolveTitle(for intent: AddTodoIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let title = intent.title, !title.isEmpty {
            completion(.success(with: title))
        } else {
            completion(.needsValue())
        }
    }
}

// MARK: - 添加面试
class AddInterviewIntentHandler: NSObject, AddInterviewIntentHandling {
    func handle(intent: AddInterviewIntent, completion: @escaping (AddInterviewIntentResponse) -> Void) {
        guard let company = intent.company, !company.isEmpty,
              let position = intent.position, !position.isEmpty else {
            completion(AddInterviewIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        let entity = InterviewEntity(context: context)
        entity.id = UUID()
        entity.company = company
        entity.position = position
        entity.ddl = intent.ddl ?? Date()
        entity.status = 0
        entity.notes = intent.notes ?? ""
        entity.location = intent.location ?? ""
        entity.salary = intent.salary ?? ""
        entity.createdAt = Date()
        
        do {
            try context.save()
            let response = AddInterviewIntentResponse(code: .success, userActivity: nil)
            response.interviewID = entity.id?.uuidString
            completion(response)
        } catch {
            completion(AddInterviewIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
    func resolveCompany(for intent: AddInterviewIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let company = intent.company, !company.isEmpty {
            completion(.success(with: company))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolvePosition(for intent: AddInterviewIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let position = intent.position, !position.isEmpty {
            completion(.success(with: position))
        } else {
            completion(.needsValue())
        }
    }
}

// MARK: - 添加会议/期刊
class AddConferenceIntentHandler: NSObject, AddConferenceIntentHandling {
    func handle(intent: AddConferenceIntent, completion: @escaping (AddConferenceIntentResponse) -> Void) {
        guard let name = intent.name, !name.isEmpty else {
            completion(AddConferenceIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        let entity = ConferenceEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.type = intent.type?.int16Value ?? 0
        entity.category = intent.category ?? AcademicCategory.other.rawValue
        entity.ddl = intent.ddl
        entity.location = intent.location ?? ""
        entity.website = intent.website ?? ""
        entity.notes = intent.notes ?? ""
        entity.createdAt = Date()
        
        do {
            try context.save()
            let response = AddConferenceIntentResponse(code: .success, userActivity: nil)
            response.conferenceID = entity.id?.uuidString
            completion(response)
        } catch {
            completion(AddConferenceIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
    func resolveName(for intent: AddConferenceIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let name = intent.name, !name.isEmpty {
            completion(.success(with: name))
        } else {
            completion(.needsValue())
        }
    }
}

// MARK: - 获取待办列表
class GetTodoListIntentHandler: NSObject, GetTodoListIntentHandling {
    func handle(intent: GetTodoListIntent, completion: @escaping (GetTodoListIntentResponse) -> Void) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TodoItemEntity> = TodoItemEntity.fetchRequest()
        
        // 根据筛选条件
        if let filter = intent.filter {
            switch filter {
            case .active:
                request.predicate = NSPredicate(format: "isCompleted == NO")
            case .completed:
                request.predicate = NSPredicate(format: "isCompleted == YES")
            case .all:
                break
            default:
                break
            }
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TodoItemEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TodoItemEntity.priority, ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            let todos = entities.prefix(10).map { entity -> IntentTodoItem in
                let item = IntentTodoItem(
                    identifier: entity.id?.uuidString ?? UUID().uuidString,
                    display: entity.title ?? ""
                )
                item.title = entity.title
                item.isCompleted = entity.isCompleted as NSNumber
                item.priority = entity.priority as NSNumber
                return item
            }
            
            let response = GetTodoListIntentResponse(code: .success, userActivity: nil)
            response.todos = todos
            response.count = todos.count as NSNumber
            completion(response)
        } catch {
            completion(GetTodoListIntentResponse(code: .failure, userActivity: nil))
        }
    }
}

// MARK: - 获取面试列表
class GetInterviewListIntentHandler: NSObject, GetInterviewListIntentHandling {
    func handle(intent: GetInterviewListIntent, completion: @escaping (GetInterviewListIntentResponse) -> Void) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<InterviewEntity> = InterviewEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InterviewEntity.ddl, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            let interviews = entities.prefix(10).map { entity -> IntentInterviewItem in
                let item = IntentInterviewItem(
                    identifier: entity.id?.uuidString ?? UUID().uuidString,
                    display: "\(entity.company ?? "") - \(entity.position ?? "")"
                )
                item.company = entity.company
                item.position = entity.position
                item.status = entity.status as NSNumber
                return item
            }
            
            let response = GetInterviewListIntentResponse(code: .success, userActivity: nil)
            response.interviews = interviews
            response.count = interviews.count as NSNumber
            completion(response)
        } catch {
            completion(GetInterviewListIntentResponse(code: .failure, userActivity: nil))
        }
    }
}
