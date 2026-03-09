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
                // 识别截图快捷指令
                AppShortcut(
                    intent: RecognizeScreenshotIntent(),
                    phrases: [
                        "识别截图用\(.applicationName)",
                        "用\(.applicationName)识别图片",
                        "\(.applicationName)识别截图",
                        "截图识别\(.applicationName)"
                    ],
                    shortTitle: "识别截图",
                    systemImageName: "doc.text.viewfinder"
                ),

                // 从图片快速添加快捷指令
                AppShortcut(
                    intent: QuickAddFromImageIntent(),
                    phrases: [
                        "用\(.applicationName)从图片添加",
                        "\(.applicationName)图片快速添加",
                        "用\(.applicationName)识别并保存"
                    ],
                    shortTitle: "从图片快速添加",
                    systemImageName: "plus.square.on.square"
                ),

                // 打开AI识图快捷指令
                AppShortcut(
                    intent: OpenAIRecognitionIntent(),
                    phrases: [
                        "打开\(.applicationName)识图",
                        "\(.applicationName)AI识图",
                        "用\(.applicationName)拍照识别"
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
    static var description: IntentDescription = IntentDescription("打开生活助手的AI识图功能，可以拍照或选择图片进行识别")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // 发送通知让App切换到AI识图tab
        NotificationCenter.default.post(name: Notification.Name("OpenAIRecognitionTab"), object: nil)
        return .result()
    }
}