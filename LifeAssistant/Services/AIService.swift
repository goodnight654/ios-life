//
//  AIService.swift
//  LifeAssistant
//

import Foundation
import UIKit
import CoreData
import Vision
import NaturalLanguage

enum AIRecognitionType: String, CaseIterable {
    case receipt = "receipt"
    case todo = "todo"
    case unknown = "unknown"
}

struct AIRecognitionResult {
    let type: AIRecognitionType
    let text: String
    let extractedData: ExtractedData?
    let confidence: Double
}

struct ExtractedData {
    let amount: Double?
    let category: AccountCategory?
    let title: String?
    let dueDate: Date?
    let merchant: String?
    let items: [String]?
}

class AIService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: AIRecognitionResult?
    @Published var recognitionHistory: [AIRecognitionRecord] = []
    @Published var lastError: String?

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchHistory()
    }

    // MARK: - Main Recognition Methods

    func recognizeImage(_ image: UIImage, completion: @escaping (AIRecognitionResult?) -> Void) {
        isProcessing = true
        lastError = nil

        debugLog("========== AIService 开始识别 ==========")
        debugLog("图片尺寸: \(image.size)")

        // 使用 SiliconFlow API 进行智能识别
        SiliconFlowService.shared.recognizeImage(image) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isProcessing = false

                switch result {
                case .success(let intelligentResult):
                    debugLog("✅ SiliconFlow API 识别成功")
                    debugLog("类型: \(intelligentResult.type.rawValue)")

                    // 转换为 AIRecognitionResult
                    let aiResult = self.convertToAIRecognitionResult(intelligentResult, image: image)

                    // 保存记录
                    self.saveRecognition(image: image, result: aiResult)

                    self.lastResult = aiResult
                    self.fetchHistory()
                    completion(aiResult)

                case .failure(let error):
                    debugLog("❌ SiliconFlow API 失败: \(error.localizedDescription)")
                    debugLog("回退到本地 OCR...")
                    self.lastError = "AI识别失败: \(error.localizedDescription)"

                    // 回退到本地 OCR
                    self.performLocalRecognition(image: image, completion: completion)
                }
            }
        }
    }

    // MARK: - 本地识别（备用）

    private func performLocalRecognition(image: UIImage, completion: @escaping (AIRecognitionResult?) -> Void) {
        performLocalOCR(on: image) { [weak self] recognizedText in
            guard let self = self else { return }

            guard let text = recognizedText, !text.isEmpty else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(nil)
                }
                return
            }

            // 分析文本类型和内容
            let result = self.analyzeRecognizedText(text)

            // 保存记录
            self.saveRecognition(image: image, result: result)

            DispatchQueue.main.async {
                self.isProcessing = false
                self.lastResult = result
                self.fetchHistory()
                completion(result)
            }
        }
    }

    // MARK: - 转换结果

    private func convertToAIRecognitionResult(_ intelligentResult: IntelligentRecognitionResult, image: UIImage) -> AIRecognitionResult {
        let type: AIRecognitionType
        switch intelligentResult.type {
        case .account:
            type = .receipt
        case .todo:
            type = .todo
        case .unknown:
            type = .unknown
        }

        var extractedData: ExtractedData?

        if let accountData = intelligentResult.accountData {
            let category = mapCategoryString(accountData.category)
            extractedData = ExtractedData(
                amount: accountData.amount,
                category: category,
                title: nil,
                dueDate: nil,
                merchant: accountData.merchant,
                items: nil
            )
        } else if let todoData = intelligentResult.todoData {
            extractedData = ExtractedData(
                amount: nil,
                category: nil,
                title: todoData.title,
                dueDate: todoData.dueDate,
                merchant: nil,
                items: nil
            )
        }

        return AIRecognitionResult(
            type: type,
            text: intelligentResult.rawText,
            extractedData: extractedData,
            confidence: intelligentResult.confidence
        )
    }

    private func mapCategoryString(_ category: String) -> AccountCategory {
        let categoryMap: [String: AccountCategory] = [
            "餐饮": .food,
            "交通": .transport,
            "购物": .shopping,
            "娱乐": .entertainment,
            "住房": .housing,
            "医疗": .medical,
            "教育": .education,
            "工资": .salary,
            "投资": .investment
        ]
        return categoryMap[category] ?? .other
    }

    // MARK: - Local OCR (Fallback)

    private func performLocalOCR(on image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            completion(recognizedStrings.joined(separator: "\n"))
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]

        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing OCR: \(error)")
            completion(nil)
        }
    }

    // MARK: - Text Analysis (Local Fallback)

    private func analyzeRecognizedText(_ text: String) -> AIRecognitionResult {
        let lowercased = text.lowercased()

        var type: AIRecognitionType = .unknown
        var confidence: Double = 0.5

        // 收据特征词
        let receiptKeywords = ["发票", "收据", "小票", "金额", "总计", "合计", "total", "amount", "¥", "$", "元", "invoice", "receipt"]
        // 待办特征词
        let todoKeywords = ["任务", "待办", "todo", "task", "截止", "ddl", "deadline", "提醒", "完成", "checklist"]

        let receiptScore = receiptKeywords.filter { lowercased.contains($0) }.count
        let todoScore = todoKeywords.filter { lowercased.contains($0) }.count

        if receiptScore > todoScore && receiptScore > 0 {
            type = .receipt
            confidence = min(0.5 + Double(receiptScore) * 0.1, 0.95)
        } else if todoScore > 0 {
            type = .todo
            confidence = min(0.5 + Double(todoScore) * 0.1, 0.95)
        }

        let extractedData = extractData(from: text, type: type)

        return AIRecognitionResult(
            type: type,
            text: text,
            extractedData: extractedData,
            confidence: confidence
        )
    }

    private func extractData(from text: String, type: AIRecognitionType) -> ExtractedData {
        var amount: Double?
        var category: AccountCategory?
        var title: String?
        var dueDate: Date?
        var merchant: String?
        var items: [String]?

        // 提取金额（支持 ¥100.00、100元、$100 等格式）
        let amountPattern = #"[¥$￥]\s*(\d+(?:\.\d{1,2})?)|(\d+(?:\.\d{1,2})?)\s*[元¥$]"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            let range = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            if let swiftRange = Range(range, in: text) {
                amount = Double(text[swiftRange])
            }
        }

        // 根据内容推断分类
        if type == .receipt {
            category = inferCategory(from: text)

            // 尝试提取商家名称（通常是第一行或包含特定关键词的行）
            let lines = text.components(separatedBy: .newlines)
            merchant = lines.first { line in
                !line.isEmpty && !line.contains("¥") && !line.contains("$") && !line.contains("元")
            }

            // 提取商品列表
            items = lines.filter { line in
                let lowercased = line.lowercased()
                return !lowercased.contains("总计") && !lowercased.contains("合计") && !lowercased.contains("total")
            }
        } else if type == .todo {
            // 提取标题（通常是第一行或包含"任务"、"todo"等的行）
            let lines = text.components(separatedBy: .newlines)
            title = lines.first { !$0.isEmpty }

            // 提取日期
            dueDate = extractDate(from: text)
        }

        return ExtractedData(
            amount: amount,
            category: category,
            title: title,
            dueDate: dueDate,
            merchant: merchant,
            items: items
        )
    }

    private func inferCategory(from text: String) -> AccountCategory? {
        let lowercased = text.lowercased()

        if lowercased.contains("餐厅") || lowercased.contains("餐饮") || lowercased.contains("food") || lowercased.contains("restaurant") {
            return .food
        } else if lowercased.contains("交通") || lowercased.contains("地铁") || lowercased.contains("公交") || lowercased.contains("transport") {
            return .transport
        } else if lowercased.contains("购物") || lowercased.contains("超市") || lowercased.contains("shop") || lowercased.contains("store") {
            return .shopping
        } else if lowercased.contains("娱乐") || lowercased.contains("电影") || lowercased.contains("entertainment") {
            return .entertainment
        } else if lowercased.contains("医疗") || lowercased.contains("医院") || lowercased.contains("medical") {
            return .medical
        }

        return nil
    }

    private func extractDate(from text: String) -> Date? {
        let patternFormats: [(pattern: String, formats: [String], needsCurrentYear: Bool)] = [
            (#"(\d{4})[-/](\d{1,2})[-/](\d{1,2})"#, ["yyyy-M-d", "yyyy/MM/dd", "yyyy-MM-dd"], false),
            (#"(\d{1,2})[-/](\d{1,2})[-/](\d{4})"#, ["d/M/yyyy", "dd/MM/yyyy", "d-M-yyyy", "dd-MM-yyyy"], false),
            (#"(\d{1,2})月(\d{1,2})日"#, ["M月d日", "MM月dd日"], true)
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        for item in patternFormats {
            guard let regex = try? NSRegularExpression(pattern: item.pattern, options: []),
                  let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) else {
                continue
            }

            let matchedString = (text as NSString).substring(with: match.range)
            for format in item.formats {
                formatter.dateFormat = format
                if let parsedDate = formatter.date(from: matchedString) {
                    if item.needsCurrentYear {
                        let calendar = Calendar.current
                        let currentYear = calendar.component(.year, from: Date())
                        let month = calendar.component(.month, from: parsedDate)
                        let day = calendar.component(.day, from: parsedDate)
                        var components = DateComponents()
                        components.year = currentYear
                        components.month = month
                        components.day = day
                        return calendar.date(from: components)
                    }
                    return parsedDate
                }
            }
        }

        return nil
    }

    // MARK: - History Management

    private func saveRecognition(image: UIImage, result: AIRecognitionResult) {
        let entity = AIRecognitionRecordEntity(context: viewContext)
        entity.id = UUID()
        entity.imageData = image.jpegData(compressionQuality: 0.7)
        entity.recognizedText = result.text
        entity.category = result.type.rawValue

        if let data = result.extractedData {
            let dict: [String: Any] = [
                "amount": data.amount as Any,
                "category": data.category?.rawValue as Any,
                "title": data.title as Any,
                "dueDate": data.dueDate?.timeIntervalSince1970 as Any,
                "merchant": data.merchant as Any,
                "items": data.items as Any
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                entity.extractedData = jsonString
            }
        }

        entity.createdAt = Date()

        do {
            try viewContext.save()
        } catch {
            print("Error saving recognition: \(error)")
        }
    }

    func fetchHistory() {
        let request: NSFetchRequest<AIRecognitionRecordEntity> = AIRecognitionRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AIRecognitionRecordEntity.createdAt, ascending: false)]
        request.fetchLimit = 50

        do {
            let entities = try viewContext.fetch(request)
            recognitionHistory = entities.map { entity in
                AIRecognitionRecord(
                    id: entity.id ?? UUID(),
                    imageData: entity.imageData,
                    recognizedText: entity.recognizedText ?? "",
                    category: AIRecognitionType(rawValue: entity.category ?? "unknown") ?? .unknown,
                    createdAt: entity.createdAt ?? Date()
                )
            }
        } catch {
            print("Error fetching history: \(error)")
        }
    }

    func deleteRecord(_ record: AIRecognitionRecord) {
        let request: NSFetchRequest<AIRecognitionRecordEntity> = AIRecognitionRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

        do {
            let results = try viewContext.fetch(request)
            if let entity = results.first {
                viewContext.delete(entity)
                try viewContext.save()
                fetchHistory()
            }
        } catch {
            print("Error deleting record: \(error)")
        }
    }
}

// MARK: - AI Recognition Record Model

struct AIRecognitionRecord: Identifiable {
    let id: UUID
    let imageData: Data?
    let recognizedText: String
    let category: AIRecognitionType
    let createdAt: Date

    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}