//
//  RecognizeImageIntent.swift
//  LifeAssistant
//
//  快捷指令专用 - 识别图片并保存数据
//

import AppIntents
import SwiftUI
import Vision

// MARK: - 识别截图Intent

@available(iOS 16.0, *)
struct RecognizeScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "识别截图"
    static var description: IntentDescription = IntentDescription("从截图中识别记账或待办信息，并保存到生活助手")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "图片", description: "要识别的截图或图片")
    var image: IntentFile

    @Parameter(title: "自动保存", description: "识别后是否自动保存", default: true)
    var autoSave: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$autoSave, .equalTo, true) {
            Summary("识别\(\.$image)并自动保存")
        } otherwise: {
            Summary("识别\(\.$image)")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        debugLog("========== RecognizeScreenshotIntent 开始 ==========")

        // 获取图片数据
        let imageData = image.data
        debugLog("图片数据大小: \(imageData.count) bytes")

        guard let uiImage = UIImage(data: imageData) else {
            debugLog("❌ 无法转换为 UIImage", category: "ERROR")
            return .result(dialog: "无法读取图片，请确保提供了有效的图片")
        }

        debugLog("UIImage 尺寸: \(uiImage.size)")
        debugLog("自动保存: \(autoSave)")

        // 调用 AI 识别
        var result: IntelligentRecognitionResult?
        var apiError: String?

        do {
            debugLog("调用 SiliconFlow API...")
            result = try await SiliconFlowService.shared.recognizeImage(uiImage)
            debugLog("✅ API 调用成功")
        } catch {
            apiError = error.localizedDescription
            debugLog("❌ API 调用失败: \(error)", category: "ERROR")
        }

        // 如果 API 失败，回退到本地 OCR
        if result == nil {
            debugLog("回退到本地 OCR...")
            result = await performLocalRecognition(on: uiImage)
        }

        guard let result = result else {
            debugLog("❌ 识别结果为空", category: "ERROR")
            return .result(dialog: "识别失败: \(apiError ?? "未知错误")")
        }

        // 构建结果消息
        let dialogMessage = buildResultMessage(for: result, autoSave: autoSave)
        return .result(dialog: IntentDialog(stringLiteral: dialogMessage))
    }

    // MARK: - 构建结果消息

    @MainActor
    private func buildResultMessage(for result: IntelligentRecognitionResult, autoSave: Bool) -> String {
        // 自动保存
        if autoSave {
            let (saved, message) = saveRecognitionResult(result)
            return message
        }

        // 返回识别结果
        let typeDescription: String
        switch result.type {
        case .account:
            typeDescription = "记账"
        case .todo:
            typeDescription = "待办"
        case .unknown:
            typeDescription = "未识别"
        }

        var detailsText = ""

        if let accountData = result.accountData {
            let absAmount = abs(accountData.amount)
            if absAmount > 0 {
                detailsText += "金额: ¥\(absAmount)\n"
            }
            if !accountData.category.isEmpty {
                detailsText += "分类: \(accountData.category)\n"
            }
            if !accountData.note.isEmpty {
                detailsText += "备注: \(accountData.note)\n"
            }
        }

        if let todoData = result.todoData {
            if !todoData.title.isEmpty {
                detailsText += "标题: \(todoData.title)\n"
            }
            if let notes = todoData.notes, !notes.isEmpty {
                detailsText += "详情: \(notes)\n"
            }
        }

        return "识别类型: \(typeDescription)\n\(detailsText)"
    }

    // MARK: - 保存结果

    @MainActor
    private func saveRecognitionResult(_ result: IntelligentRecognitionResult) -> (Bool, String) {
        switch result.type {
        case .account:
            guard let accountData = result.accountData else {
                debugLog("❌ 记账数据为空", category: "ERROR")
                return (false, "记账数据为空，无法保存")
            }

            let absAmount = abs(accountData.amount)
            guard absAmount > 0 else {
                debugLog("❌ 金额无效: \(accountData.amount)", category: "ERROR")
                return (false, "金额无效，无法保存")
            }

            let pendingData = PendingAccountData(
                amount: absAmount,
                category: mapCategory(accountData.category),
                note: accountData.note,
                merchant: accountData.merchant,
                isExpense: accountData.amount < 0,
                createdAt: Date()
            )

            debugLog("准备保存记账: amount=\(absAmount), category=\(accountData.category), isExpense=\(accountData.amount < 0)")

            // 先尝试直接保存到 CoreData
            if ShortcutsDataManager.shared.saveAccountToCoreData(pendingData) {
                return (true, "已保存记账: ¥\(absAmount)，分类: \(accountData.category)")
            }

            // 如果失败，保存到 UserDefaults 作为备份
            if ShortcutsDataManager.shared.saveAccountData(pendingData) {
                return (true, "已保存记账(待同步): ¥\(absAmount)")
            }

            return (false, "保存失败，请稍后重试")

        case .todo:
            guard let todoData = result.todoData, !todoData.title.isEmpty else {
                debugLog("❌ 待办数据为空", category: "ERROR")
                return (false, "待办数据为空，无法保存")
            }

            let pendingData = PendingTodoData(
                title: todoData.title,
                notes: todoData.notes,
                dueDate: todoData.dueDate,
                priority: todoData.priority,
                createdAt: Date()
            )

            debugLog("准备保存待办: title=\(todoData.title)")

            // 先尝试直接保存到 CoreData
            if ShortcutsDataManager.shared.saveTodoToCoreData(pendingData) {
                return (true, "已保存待办: \(todoData.title)")
            }

            // 如果失败，保存到 UserDefaults 作为备份
            if ShortcutsDataManager.shared.saveTodoData(pendingData) {
                return (true, "已保存待办(待同步): \(todoData.title)")
            }

            return (false, "保存失败，请稍后重试")

        case .unknown:
            debugLog("❌ 未知类型", category: "ERROR")
            return (false, "无法识别图片类型")
        }
    }

    // MARK: - 本地识别

    private func performLocalRecognition(on image: UIImage) async -> IntelligentRecognitionResult {
        let recognizedText = await performOCR(on: image)

        guard !recognizedText.isEmpty else {
            return IntelligentRecognitionResult(
                type: .unknown,
                accountData: nil,
                todoData: nil,
                rawText: "",
                confidence: 0
            )
        }

        let lowercased = recognizedText.lowercased()
        let receiptKeywords = ["发票", "收据", "小票", "金额", "总计", "合计", "total", "amount", "¥", "$", "元", "支付", "付款", "订单"]
        let todoKeywords = ["任务", "待办", "todo", "task", "截止", "ddl", "deadline", "提醒", "完成", "事项"]

        let receiptScore = receiptKeywords.filter { lowercased.contains($0) }.count
        let todoScore = todoKeywords.filter { lowercased.contains($0) }.count

        var type: IntelligentRecognitionResult.RecognitionType = .unknown
        if receiptScore > todoScore && receiptScore > 0 {
            type = .account
        } else if todoScore > 0 {
            type = .todo
        }

        var amount: Double = 0
        let amountPattern = #"[¥$￥]\s*(\d+(?:\.\d{1,2})?)|(\d+(?:\.\d{1,2})?)\s*[元¥$]"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []),
           let match = regex.firstMatch(in: recognizedText, options: [], range: NSRange(location: 0, length: recognizedText.utf16.count)) {
            let range = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            if let swiftRange = Range(range, in: recognizedText) {
                amount = Double(recognizedText[swiftRange]) ?? 0
            }
        }

        var accountData: IntelligentRecognitionResult.AccountData?
        var todoData: IntelligentRecognitionResult.TodoData?

        if type == .account {
            accountData = IntelligentRecognitionResult.AccountData(
                amount: amount,
                category: "其他",
                note: recognizedText,
                merchant: nil,
                date: nil
            )
        } else if type == .todo {
            let lines = recognizedText.components(separatedBy: .newlines)
            let title = lines.first { !$0.isEmpty } ?? ""
            todoData = IntelligentRecognitionResult.TodoData(
                title: title,
                notes: recognizedText,
                dueDate: nil,
                priority: "medium"
            )
        }

        return IntelligentRecognitionResult(
            type: type,
            accountData: accountData,
            todoData: todoData,
            rawText: recognizedText,
            confidence: 0.5
        )
    }

    private func performOCR(on image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }

        return await withCheckedContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            try? requestHandler.perform([request])
        }
    }

    private func mapCategory(_ category: String) -> String {
        let categoryMap: [String: String] = [
            "餐饮": "餐饮",
            "交通": "交通",
            "购物": "购物",
            "娱乐": "娱乐",
            "住房": "住房",
            "医疗": "医疗",
            "教育": "教育",
            "工资": "工资",
            "投资": "投资"
        ]
        return categoryMap[category] ?? "其他"
    }
}

// MARK: - 从相册选择图片识别Intent

@available(iOS 16.0, *)
struct QuickAddFromImageIntent: AppIntent {
    static var title: LocalizedStringResource = "从图片快速添加"
    static var description: IntentDescription = IntentDescription("从相册选择图片，识别后直接添加到记账或待办")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "图片", description: "从相册选择的图片")
    var image: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let imageData = image.data
        guard let uiImage = UIImage(data: imageData) else {
            return .result(dialog: "无法读取图片")
        }

        // AI 识别
        let result: IntelligentRecognitionResult
        do {
            result = try await SiliconFlowService.shared.recognizeImage(uiImage)
        } catch {
            return .result(dialog: "AI识别失败: \(error.localizedDescription)")
        }

        // 保存
        let message = saveAndBuildMessage(for: result)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    @MainActor
    private func saveAndBuildMessage(for result: IntelligentRecognitionResult) -> String {
        switch result.type {
        case .account:
            guard let accountData = result.accountData else {
                return "无法提取记账信息"
            }

            let absAmount = abs(accountData.amount)
            guard absAmount > 0 else {
                return "金额无效"
            }

            let pendingData = PendingAccountData(
                amount: absAmount,
                category: accountData.category,
                note: accountData.note,
                merchant: accountData.merchant,
                isExpense: accountData.amount < 0,
                createdAt: Date()
            )

            if ShortcutsDataManager.shared.saveAccountToCoreData(pendingData) {
                return "已添加记账: ¥\(absAmount)，分类: \(accountData.category)"
            } else if ShortcutsDataManager.shared.saveAccountData(pendingData) {
                return "已保存记账(待同步): ¥\(absAmount)"
            } else {
                return "保存失败，请打开App查看"
            }

        case .todo:
            guard let todoData = result.todoData, !todoData.title.isEmpty else {
                return "无法提取待办信息"
            }

            let pendingData = PendingTodoData(
                title: todoData.title,
                notes: todoData.notes,
                dueDate: todoData.dueDate,
                priority: todoData.priority,
                createdAt: Date()
            )

            if ShortcutsDataManager.shared.saveTodoToCoreData(pendingData) {
                return "已添加待办: \(todoData.title)"
            } else if ShortcutsDataManager.shared.saveTodoData(pendingData) {
                return "已保存待办(待同步): \(todoData.title)"
            } else {
                return "保存失败，请打开App查看"
            }

        case .unknown:
            return "无法识别图片类型"
        }
    }
}