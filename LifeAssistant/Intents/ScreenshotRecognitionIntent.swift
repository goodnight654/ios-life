//
//  ScreenshotRecognitionIntent.swift
//  LifeAssistant
//
//  截图识别快捷指令 - 带自定义界面
//

import AppIntents
import SwiftUI
import Vision

// MARK: - 截图识别Intent (带图片选择界面)

@available(iOS 16.0, *)
struct ScreenshotRecognitionIntent: AppIntent {
    static var title: LocalizedStringResource = "截图识别"
    static var description: IntentDescription = IntentDescription("选择截图或图片，AI自动识别并保存为记账或待办")
    static var openAppWhenRun: Bool = false

    // 图片参数 - 用户可以从相册选择或传入截图
    @Parameter(title: "选择图片", description: "点击选择要识别的截图或图片")
    var selectedImage: IntentFile?

    // 保存类型选择
    @Parameter(title: "保存类型", default: .auto)
    var saveType: SaveType

    // 保存类型枚举
    enum SaveType: String, AppEnum {
        case auto = "自动识别"
        case account = "记账"
        case todo = "待办"

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "保存类型")
        static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
            .auto: "自动识别",
            .account: "保存为记账",
            .todo: "保存为待办"
        ]
    }

    static var parameterSummary: some ParameterSummary {
        Summary("识别\(\.$selectedImage)") {
            \.$saveType
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        debugLog("========== ScreenshotRecognitionIntent 开始 ==========")

        // 检查是否选择了图片
        guard let imageFile = selectedImage else {
            debugLog("❌ 未选择图片", category: "ERROR")
            return .result(dialog: "请先选择要识别的图片")
        }

        let imageData = imageFile.data
        debugLog("图片数据大小: \(imageData.count) bytes")

        guard let uiImage = UIImage(data: imageData) else {
            debugLog("❌ 无法转换为 UIImage", category: "ERROR")
            return .result(dialog: "无法读取图片，请选择有效的图片")
        }

        debugLog("UIImage 尺寸: \(uiImage.size)")
        debugLog("保存类型: \(saveType.rawValue)")

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

        // 根据 saveType 处理结果
        let message = processAndSaveResult(result, saveType: saveType)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    // MARK: - 处理和保存结果

    @MainActor
    private func processAndSaveResult(_ result: IntelligentRecognitionResult, saveType: SaveType) -> String {
        switch saveType {
        case .auto:
            return saveRecognitionResult(result)
        case .account:
            return forceSaveAsAccount(result)
        case .todo:
            return forceSaveAsTodo(result)
        }
    }

    @MainActor
    private func saveRecognitionResult(_ result: IntelligentRecognitionResult) -> String {
        switch result.type {
        case .account:
            return saveAsAccount(result.accountData)
        case .todo:
            return saveAsTodo(result.todoData)
        case .unknown:
            // 如果无法识别，默认保存为记账
            if let accountData = result.accountData {
                return saveAsAccount(result.accountData)
            }
            return "无法识别图片内容"
        }
    }

    @MainActor
    private func forceSaveAsAccount(_ result: IntelligentRecognitionResult) -> String {
        return saveAsAccount(result.accountData)
    }

    @MainActor
    private func forceSaveAsTodo(_ result: IntelligentRecognitionResult) -> String {
        return saveAsTodo(result.todoData)
    }

    // MARK: - 保存为记账

    @MainActor
    private func saveAsAccount(_ accountData: IntelligentRecognitionResult.AccountData?) -> String {
        guard let accountData = accountData else {
            return "无法提取记账信息"
        }

        let absAmount = abs(accountData.amount)
        guard absAmount > 0 else {
            return "未检测到有效金额"
        }

        let pendingData = PendingAccountData(
            amount: absAmount,
            category: mapCategory(accountData.category),
            note: accountData.note,
            merchant: accountData.merchant,
            isExpense: accountData.amount < 0,
            createdAt: Date()
        )

        debugLog("保存记账: amount=\(absAmount), category=\(accountData.category)")

        if ShortcutsDataManager.shared.saveAccountToCoreData(pendingData) {
            return "✅ 已保存记账\n金额: ¥\(absAmount)\n分类: \(accountData.category)\n备注: \(accountData.note)"
        } else if ShortcutsDataManager.shared.saveAccountData(pendingData) {
            return "✅ 已保存记账(待同步)\n金额: ¥\(absAmount)"
        }

        return "保存失败，请重试"
    }

    // MARK: - 保存为待办

    @MainActor
    private func saveAsTodo(_ todoData: IntelligentRecognitionResult.TodoData?) -> String {
        guard let todoData = todoData, !todoData.title.isEmpty else {
            return "无法提取待办信息"
        }

        let pendingData = PendingTodoData(
            title: todoData.title,
            notes: todoData.notes,
            dueDate: todoData.dueDate,
            priority: todoData.priority ?? "medium",
            createdAt: Date()
        )

        debugLog("保存待办: title=\(todoData.title)")

        if ShortcutsDataManager.shared.saveTodoToCoreData(pendingData) {
            var message = "✅ 已保存待办\n标题: \(todoData.title)"
            if let dueDate = todoData.dueDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy年MM月dd日"
                message += "\n截止: \(formatter.string(from: dueDate))"
            }
            return message
        } else if ShortcutsDataManager.shared.saveTodoData(pendingData) {
            return "✅ 已保存待办(待同步)\n标题: \(todoData.title)"
        }

        return "保存失败，请重试"
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

        if type == .account || amount > 0 {
            accountData = IntelligentRecognitionResult.AccountData(
                amount: -amount, // 默认为支出
                category: "其他",
                note: recognizedText,
                merchant: nil,
                date: nil
            )
            if type == .unknown { type = .account }
        }

        if type == .todo {
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

// MARK: - 快速添加记账Intent

@available(iOS 16.0, *)
struct QuickAddAccountIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description: IntentDescription = IntentDescription("从截图快速添加记账记录")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "选择图片", description: "点击选择截图或图片")
    var selectedImage: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Summary("识别\(\.$selectedImage)并保存为记账")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        var intent = ScreenshotRecognitionIntent()
        intent.selectedImage = selectedImage
        intent.saveType = .account
        return try await intent.perform()
    }
}

// MARK: - 快速添加待办Intent

@available(iOS 16.0, *)
struct QuickAddTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "快速待办"
    static var description: IntentDescription = IntentDescription("从截图快速添加待办事项")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "选择图片", description: "点击选择截图或图片")
    var selectedImage: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Summary("识别\(\.$selectedImage)并保存为待办")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        var intent = ScreenshotRecognitionIntent()
        intent.selectedImage = selectedImage
        intent.saveType = .todo
        return try await intent.perform()
    }
}