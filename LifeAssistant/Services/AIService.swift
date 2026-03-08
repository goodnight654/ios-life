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
    
    private let viewContext: NSManagedObjectContext
    private let openAIAPIKey: String? = nil // 用户需要配置自己的 API Key
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchHistory()
    }
    
    // MARK: - Main Recognition Methods
    
    func recognizeImage(_ image: UIImage, completion: @escaping (AIRecognitionResult?) -> Void) {
        isProcessing = true
        
        // 首先使用 Vision 框架进行本地 OCR
        performLocalOCR(on: image) { recognizedText in
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
    
    func recognizeWithOpenAI(_ image: UIImage, completion: @escaping (AIRecognitionResult?) -> Void) {
        guard let apiKey = openAIAPIKey, !apiKey.isEmpty else {
            // 如果没有配置 OpenAI API Key，回退到本地识别
            recognizeImage(image, completion: completion)
            return
        }
        
        isProcessing = true
        
        // 将图片转换为 base64
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let base64Image = imageData.base64EncodedString() else {
            isProcessing = false
            completion(nil)
            return
        }
        
        // 构建 OpenAI Vision API 请求
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an AI assistant that analyzes images to extract structured data. Identify if the image is a receipt/invoice or contains task/todo information. Return JSON with fields: type ('receipt' or 'todo'), amount (number), category (string), title (string), dueDate (ISO string or null), merchant (string), items (array of strings)."
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500,
            "response_format": ["type": "json_object"]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            isProcessing = false
            completion(nil)
            return
        }
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    completion(nil)
                    return
                }
                
                // 解析返回的 JSON
                if let resultData = content.data(using: .utf8),
                   let parsedJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] {
                    let result = self.parseOpenAIResponse(parsedJSON, originalText: content)
                    self.saveRecognition(image: image, result: result)
                    self.lastResult = result
                    self.fetchHistory()
                    completion(result)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Local OCR with Vision
    
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
    
    // MARK: - Text Analysis
    
    private func analyzeRecognizedText(_ text: String) -> AIRecognitionResult {
        let lowercased = text.lowercased()
        
        // 判断类型
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
        
        // 提取数据
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
        let datePatterns = [
            #"(\d{4})[-/](\d{1,2})[-/](\d{1,2})"#,  // 2024-01-15
            #"(\d{1,2})[-/](\d{1,2})[-/](\d{4})"#,  // 15/01/2024
            #"(\d{1,2})月(\d{1,2})日"#               // 1月15日
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                let matchedString = (text as NSString).substring(with: match.range)
                
                if matchedString.contains("月") {
                    formatter.dateFormat = "M月d日"
                } else if matchedString.contains("/") || matchedString.contains("-") {
                    if matchedString.count > 8 {
                        formatter.dateFormat = "yyyy-MM-dd"
                    } else {
                        formatter.dateFormat = "dd/MM/yyyy"
                    }
                }
                
                if let date = formatter.date(from: matchedString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func parseOpenAIResponse(_ json: [String: Any], originalText: String) -> AIRecognitionResult {
        let type = AIRecognitionType(rawValue: json["type"] as? String ?? "unknown") ?? .unknown
        
        let amount = (json["amount"] as? NSNumber)?.doubleValue
        let categoryString = json["category"] as? String
        let category = categoryString.flatMap { AccountCategory(rawValue: $0) }
        let title = json["title"] as? String
        let dueDateString = json["dueDate"] as? String
        let dueDate = dueDateString.flatMap { ISO8601DateFormatter().date(from: $0) }
        let merchant = json["merchant"] as? String
        let items = json["items"] as? [String]
        
        let extractedData = ExtractedData(
            amount: amount,
            category: category,
            title: title,
            dueDate: dueDate,
            merchant: merchant,
            items: items
        )
        
        return AIRecognitionResult(
            type: type,
            text: originalText,
            extractedData: extractedData,
            confidence: 0.9
        )
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
            entity.extractedData = try? JSONSerialization.data(withJSONObject: dict)
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
