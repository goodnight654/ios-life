//
//  SiliconFlowService.swift
//  LifeAssistant
//

import Foundation
import UIKit

// MARK: - SiliconFlow API 配置

struct SiliconFlowConfig {
    static let apiKey = "sk-aguotyuhfkiijvbsxtoxylhdsaqptbqrrrvvdddwelubadgw"
    static let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    static let model = "deepseek-ai/deepseek-vl2"  // 使用视觉模型，支持图片理解
}

// MARK: - API 响应模型

struct SiliconFlowResponse: Codable {
    let choices: [Choice]?
    let error: APIError?

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }

    struct APIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

// MARK: - 智能识别结果

struct IntelligentRecognitionResult {
    let type: RecognitionType
    let accountData: AccountData?
    let todoData: TodoData?
    let rawText: String
    let confidence: Double

    enum RecognitionType: String {
        case account = "account"
        case todo = "todo"
        case unknown = "unknown"
    }

    struct AccountData {
        let amount: Double
        let category: String
        let note: String
        let merchant: String?
        let date: Date?
    }

    struct TodoData {
        let title: String
        let notes: String?
        let dueDate: Date?
        let priority: String?
    }
}

// MARK: - 调试日志

func debugLog(_ message: String, category: String = "SiliconFlow") {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    print("[\(timestamp)] [\(category)] \(message)")
}

// MARK: - SiliconFlow Service

class SiliconFlowService {

    static let shared = SiliconFlowService()

    private init() {}

    /// 调用 SiliconFlow API 识别图片
    func recognizeImage(_ image: UIImage, completion: @escaping (Result<IntelligentRecognitionResult, Error>) -> Void) {
        debugLog("========== 开始识别图片 ==========")
        debugLog("图片尺寸: \(image.size.width) x \(image.size.height)")

        // 将图片转为 base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            debugLog("❌ 错误: 无法将图片转换为JPEG数据", category: "ERROR")
            completion(.failure(NSError(domain: "SiliconFlowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法处理图片"])))
            return
        }

        let base64Image = imageData.base64EncodedString()
        debugLog("图片数据大小: \(imageData.count) bytes, Base64长度: \(base64Image.count)")

        // 构建请求
        let systemPrompt = """
        你是一个智能助手，负责分析图片内容并提取结构化数据。

        请识别图片是"记账"(account)还是"待办"(todo)类型，并提取相关信息。

        必须返回以下JSON格式（不要包含markdown代码块标记）：
        {
            "type": "account" 或 "todo" 或 "unknown",
            "account": {
                "amount": 数字金额,
                "category": "餐饮/交通/购物/娱乐/住房/医疗/教育/工资/投资/其他",
                "note": "备注说明",
                "merchant": "商家名称（可选）"
            },
            "todo": {
                "title": "待办标题",
                "notes": "详细说明（可选）",
                "dueDate": "YYYY-MM-DD（可选）",
                "priority": "high/medium/low（可选）"
            },
            "rawText": "图片中的主要文字内容"
        }

        判断规则：
        1. 如果图片包含金额、价格、支付信息、小票、账单等，归类为"account"
        2. 如果图片包含任务、待办事项、截止日期、提醒等，归类为"todo"
        3. 如果无法确定类型，归类为"unknown"

        【重要】分类判断规则（category）：
        - 餐饮：餐厅、饭店、外卖、咖啡、奶茶、酒吧、食品店、美团外卖、饿了么、肯德基、麦当劳、星巴克等
        - 交通：打车、滴滴、Uber、出租车、地铁、公交、加油、停车、高铁、机票、火车票等
        - 购物：超市、商场、便利店、淘宝、京东、拼多多、服装店、电子产品等
        - 娱乐：电影、游戏、KTV、网吧、游乐园、演唱会、景点门票等
        - 住房：酒店、宾馆、民宿、房租、水电费、物业费、装修、家居用品等。注意：任何酒店品牌（如星程酒店、如家、汉庭、希尔顿等）都归类为"住房"
        - 医疗：医院、药店、诊所、体检、牙科、眼科等
        - 教育：培训、课程、书籍、考试报名、学费等
        - 工资：工资收入、奖金、津贴等
        - 投资：理财收益、股票、基金、利息收入等
        - 其他：无法归类的消费

        【重要】商家识别规则：
        - 仔细识别图片中的商家名称，如"星程酒店"、"麦当劳"、"滴滴出行"等
        - 根据商家名称智能判断分类
        - note应包含具体的消费内容描述

        对于记账(account)：
        - amount: 必须提取准确的数字金额
        - category: 根据商家和消费内容推断分类，严格遵守上述分类规则
        - note: 简要描述消费内容，如"星程酒店住宿"
        - merchant: 必须识别商家名称

        对于待办(todo)：
        - title: 简洁的任务标题
        - notes: 任务的详细说明
        - dueDate: 截止日期，格式YYYY-MM-DD
        - priority: 根据紧急程度判断优先级
        """

        let requestBody: [String: Any] = [
            "model": SiliconFlowConfig.model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
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
            "max_tokens": 1000,
            "temperature": 0.1
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            debugLog("❌ 错误: 无法构建JSON请求体", category: "ERROR")
            completion(.failure(NSError(domain: "SiliconFlowService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法构建请求"])))
            return
        }

        debugLog("请求体大小: \(jsonData.count) bytes")
        debugLog("API URL: \(SiliconFlowConfig.baseURL)")
        debugLog("Model: \(SiliconFlowConfig.model)")
        debugLog("API Key (前10位): \(String(SiliconFlowConfig.apiKey.prefix(10)))...")

        var request = URLRequest(url: URL(string: SiliconFlowConfig.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SiliconFlowConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 120

        debugLog("发送请求...")
        let startTime = Date()

        URLSession.shared.dataTask(with: request) { data, response, error in
            let elapsedTime = Date().timeIntervalSince(startTime)
            debugLog("收到响应，耗时: \(String(format: "%.2f", elapsedTime))秒")

            if let error = error {
                debugLog("❌ 网络错误: \(error.localizedDescription)", category: "ERROR")
                debugLog("错误详情: \(error)", category: "ERROR")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugLog("❌ 错误: 无法获取HTTP响应", category: "ERROR")
                completion(.failure(NSError(domain: "SiliconFlowService", code: -3, userInfo: [NSLocalizedDescriptionKey: "无HTTP响应"])))
                return
            }

            debugLog("HTTP状态码: \(httpResponse.statusCode)")
            debugLog("HTTP Headers: \(httpResponse.allHeaderFields)")

            guard let data = data else {
                debugLog("❌ 错误: 响应数据为空", category: "ERROR")
                completion(.failure(NSError(domain: "SiliconFlowService", code: -4, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }

            debugLog("响应数据大小: \(data.count) bytes")

            // 打印原始响应
            if let rawString = String(data: data, encoding: .utf8) {
                debugLog("原始响应内容:\n\(rawString)")
            }

            // 解析 API 响应
            do {
                let apiResponse = try JSONDecoder().decode(SiliconFlowResponse.self, from: data)

                // 检查API错误
                if let apiError = apiResponse.error {
                    debugLog("❌ API返回错误: \(apiError.message)", category: "ERROR")
                    debugLog("错误类型: \(apiError.type ?? "unknown"), 错误代码: \(apiError.code ?? "unknown")", category: "ERROR")
                    completion(.failure(NSError(domain: "SiliconFlowService", code: -100, userInfo: [NSLocalizedDescriptionKey: apiError.message])))
                    return
                }

                guard let choices = apiResponse.choices, let firstChoice = choices.first else {
                    debugLog("❌ 错误: 响应中没有choices", category: "ERROR")
                    completion(.failure(NSError(domain: "SiliconFlowService", code: -5, userInfo: [NSLocalizedDescriptionKey: "无法解析响应"])))
                    return
                }

                let content = firstChoice.message.content
                debugLog("AI返回内容:\n\(content)")

                // 解析 AI 返回的 JSON
                let result = try self.parseAIResponse(content)
                debugLog("✅ 解析成功!")
                debugLog("识别类型: \(result.type.rawValue)")
                if let accountData = result.accountData {
                    debugLog("记账数据: 金额=\(accountData.amount), 分类=\(accountData.category), 备注=\(accountData.note)")
                }
                if let todoData = result.todoData {
                    debugLog("待办数据: 标题=\(todoData.title)")
                }
                debugLog("========== 识别完成 ==========")
                completion(.success(result))

            } catch let decodingError as DecodingError {
                debugLog("❌ JSON解码错误: \(decodingError)", category: "ERROR")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    debugLog("缺少键: \(key.stringValue), 上下文: \(context.debugDescription)", category: "ERROR")
                case .typeMismatch(let type, let context):
                    debugLog("类型不匹配: 期望\(type), 上下文: \(context.debugDescription)", category: "ERROR")
                case .valueNotFound(let type, let context):
                    debugLog("值为空: \(type), 上下文: \(context.debugDescription)", category: "ERROR")
                case .dataCorrupted(let context):
                    debugLog("数据损坏: \(context.debugDescription)", category: "ERROR")
                @unknown default:
                    debugLog("未知解码错误", category: "ERROR")
                }
                completion(.failure(decodingError))
            } catch {
                debugLog("❌ 其他错误: \(error.localizedDescription)", category: "ERROR")
                completion(.failure(error))
            }
        }.resume()
    }

    /// 异步版本
    func recognizeImage(_ image: UIImage) async throws -> IntelligentRecognitionResult {
        return try await withCheckedThrowingContinuation { continuation in
            recognizeImage(image) { result in
                switch result {
                case .success(let recognitionResult):
                    continuation.resume(returning: recognitionResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 解析 AI 返回的 JSON
    private func parseAIResponse(_ content: String) throws -> IntelligentRecognitionResult {
        debugLog("开始解析AI响应...")

        // 清理可能的 markdown 代码块标记
        var cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        debugLog("原始内容长度: \(content.count)")

        if cleanedContent.hasPrefix("```json") {
            debugLog("检测到```json标记，正在移除...")
            cleanedContent = String(cleanedContent.dropFirst(7))
        } else if cleanedContent.hasPrefix("```") {
            debugLog("检测到```标记，正在移除...")
            cleanedContent = String(cleanedContent.dropFirst(3))
        }
        if cleanedContent.hasSuffix("```") {
            cleanedContent = String(cleanedContent.dropLast(3))
        }
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)

        debugLog("清理后内容:\n\(cleanedContent)")

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            debugLog("❌ 无法将内容转换为UTF-8数据", category: "ERROR")
            throw NSError(domain: "SiliconFlowService", code: -5, userInfo: [NSLocalizedDescriptionKey: "无法转换响应数据"])
        }

        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            debugLog("❌ 无法解析JSON", category: "ERROR")
            throw NSError(domain: "SiliconFlowService", code: -6, userInfo: [NSLocalizedDescriptionKey: "无法解析JSON"])
        }

        debugLog("JSON解析成功: \(json.keys)")

        let typeString = json["type"] as? String ?? "unknown"
        let type = IntelligentRecognitionResult.RecognitionType(rawValue: typeString) ?? .unknown
        let rawText = json["rawText"] as? String ?? ""

        debugLog("类型: \(typeString), rawText: \(rawText)")

        var accountData: IntelligentRecognitionResult.AccountData?
        var todoData: IntelligentRecognitionResult.TodoData?

        if type == .account, let account = json["account"] as? [String: Any] {
            debugLog("解析记账数据: \(account)")
            let amount = (account["amount"] as? NSNumber)?.doubleValue ?? 0
            let category = account["category"] as? String ?? "其他"
            let note = account["note"] as? String ?? ""
            let merchant = account["merchant"] as? String

            accountData = IntelligentRecognitionResult.AccountData(
                amount: amount,
                category: category,
                note: note,
                merchant: merchant,
                date: nil
            )
            debugLog("记账数据解析完成: amount=\(amount), category=\(category)")
        }

        if type == .todo, let todo = json["todo"] as? [String: Any] {
            debugLog("解析待办数据: \(todo)")
            let title = todo["title"] as? String ?? ""
            let notes = todo["notes"] as? String
            let dueDateString = todo["dueDate"] as? String
            let priority = todo["priority"] as? String

            var dueDate: Date?
            if let dueDateString = dueDateString {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                dueDate = formatter.date(from: dueDateString)
                debugLog("截止日期: \(dueDateString) -> \(String(describing: dueDate))")
            }

            todoData = IntelligentRecognitionResult.TodoData(
                title: title,
                notes: notes,
                dueDate: dueDate,
                priority: priority
            )
            debugLog("待办数据解析完成: title=\(title)")
        }

        return IntelligentRecognitionResult(
            type: type,
            accountData: accountData,
            todoData: todoData,
            rawText: rawText,
            confidence: 0.9
        )
    }
}