//
//  PersistenceController.swift
//  LifeAssistant
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // 使用 NSPersistentContainer 而不是 NSPersistentCloudKitContainer
        // 个人开发者账户不支持 iCloud
        container = NSPersistentContainer(name: "LifeAssistant")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to get persistent store description")
        }

        // 配置 App Groups 共享存储（用于快捷指令访问）
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.LifeAssistant") {
            let storeURL = appGroupURL.appendingPathComponent("LifeAssistant.sqlite")
            description.url = storeURL
            debugLog("CoreData 存储路径: \(storeURL.path)")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                debugLog("❌ CoreData 加载失败: \(error)", category: "ERROR")
                // 不要 fatalError，允许 App 继续运行
            } else {
                debugLog("✅ CoreData 加载成功: \(description.url?.path ?? "unknown")")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                debugLog("✅ CoreData 保存成功")
            } catch {
                debugLog("❌ CoreData 保存失败: \(error)", category: "ERROR")
            }
        }
    }

    // 获取后台上下文，用于快捷指令等后台操作
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}