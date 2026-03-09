//
//  LifeAssistantShortcuts.swift
//  LifeAssistant
//

import AppIntents

@available(iOS 16.0, *)
struct LifeAssistantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        get {
            return [
                // 截图识别 - 主快捷指令
                AppShortcut(
                    intent: ScreenshotRecognitionIntent(),
                    phrases: [
                        "识别截图用\(.applicationName)",
                        "用\(.applicationName)识别图片",
                        "\(.applicationName)截图识别",
                        "截图识别\(.applicationName)"
                    ],
                    shortTitle: "截图识别",
                    systemImageName: "doc.text.viewfinder"
                ),

                // 快速记账
                AppShortcut(
                    intent: QuickAddAccountIntent(),
                    phrases: [
                        "用\(.applicationName)快速记账",
                        "\(.applicationName)记账",
                        "截图记账\(.applicationName)"
                    ],
                    shortTitle: "快速记账",
                    systemImageName: "yensign.circle"
                ),

                // 快速待办
                AppShortcut(
                    intent: QuickAddTodoIntent(),
                    phrases: [
                        "用\(.applicationName)快速待办",
                        "\(.applicationName)待办",
                        "截图待办\(.applicationName)"
                    ],
                    shortTitle: "快速待办",
                    systemImageName: "checklist"
                ),

                // 打开AI识图
                AppShortcut(
                    intent: OpenAIRecognitionIntent(),
                    phrases: [
                        "打开\(.applicationName)识图",
                        "\(.applicationName)AI识图"
                    ],
                    shortTitle: "打开AI识图",
                    systemImageName: "camera.viewfinder"
                )
            ]
        }
    }
}

// MARK: - 打开AI识图Intent
@available(iOS 16.0, *)
struct OpenAIRecognitionIntent: AppIntent {
    static var title: LocalizedStringResource = "打开AI识图"
    static var description: IntentDescription = IntentDescription("打开生活助手的AI识图功能")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("OpenAIRecognitionTab"), object: nil)
        return .result()
    }
}