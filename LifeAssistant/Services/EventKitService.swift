//
//  EventKitService.swift
//  LifeAssistant
//

import Foundation
import EventKit
import SwiftUI

class EventKitService: ObservableObject {
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isAuthorized = false
    
    private let eventStore = EKEventStore()
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        isAuthorized = authorizationStatus == .fullAccess
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        eventStore.requestFullAccessToReminders { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.checkAuthorizationStatus()
                completion(granted)
            }
        }
    }
    
    // MARK: - Reminder Operations
    
    func createReminder(title: String, notes: String? = nil, dueDate: Date? = nil, priority: EKReminderPriority = .none) -> String? {
        guard isAuthorized else { return nil }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority.rawValue
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            
            // 添加提醒（截止前1小时）
            let alarm = EKAlarm(absoluteDate: dueDate.addingTimeInterval(-3600))
            reminder.addAlarm(alarm)
        }
        
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        do {
            try eventStore.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            print("Error creating reminder: \(error)")
            return nil
        }
    }
    
    func updateReminder(identifier: String, title: String? = nil, notes: String? = nil, dueDate: Date? = nil, isCompleted: Bool? = nil) {
        guard isAuthorized,
              let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return
        }
        
        if let title = title {
            reminder.title = title
        }
        if let notes = notes {
            reminder.notes = notes
        }
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        if let isCompleted = isCompleted {
            reminder.isCompleted = isCompleted
        }
        
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            print("Error updating reminder: \(error)")
        }
    }
    
    func deleteReminder(identifier: String) {
        guard isAuthorized,
              let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return
        }
        
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            print("Error deleting reminder: \(error)")
        }
    }
    
    func getReminder(identifier: String) -> EKReminder? {
        guard isAuthorized else { return nil }
        return eventStore.calendarItem(withIdentifier: identifier) as? EKReminder
    }
    
    // MARK: - Calendar Operations
    
    func createCalendarEvent(title: String, notes: String? = nil, startDate: Date, endDate: Date, location: String? = nil, isAllDay: Bool = false) -> String? {
        guard isAuthorized else { return nil }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.isAllDay = isAllDay
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // 添加提醒（开始前15分钟）
        let alarm = EKAlarm(relativeOffset: -900)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Error creating calendar event: \(error)")
            return nil
        }
    }
    
    // MARK: - Batch Operations
    
    func syncTodosToReminders(todos: [TodoItem], completion: @escaping ([UUID: String]) -> Void) {
        guard isAuthorized else {
            completion([:])
            return
        }
        
        var syncedIDs: [UUID: String] = [:]
        let group = DispatchGroup()
        
        for todo in todos where todo.reminderID == nil && todo.dueDate != nil {
            group.enter()
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let reminderID = self.createReminder(
                    title: todo.title,
                    notes: todo.notes,
                    dueDate: todo.dueDate
                ) {
                    syncedIDs[todo.id] = reminderID
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(syncedIDs)
        }
    }
    
    // MARK: - Settings
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - EKReminderPriority Extension

extension EKReminderPriority {
    static let none = EKReminderPriority(rawValue: 0)
    static let high = EKReminderPriority(rawValue: 1)
    static let medium = EKReminderPriority(rawValue: 5)
    static let low = EKReminderPriority(rawValue: 9)
}
