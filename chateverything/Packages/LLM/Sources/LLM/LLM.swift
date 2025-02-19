import Foundation

public struct Message: Codable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct ChatRequest: Codable {
    public let model: String
    public let messages: [Message]
    public let format: String
    public let stream: Bool
    
    public init(model: String, messages: [Message], format: String, stream: Bool) {
        self.model = model
        self.messages = messages
        self.format = format
        self.stream = stream
    }
}

// 定义响应处理器类型
public typealias ResponseHandler = (Data) throws -> String

public struct LanguageProvider: Identifiable {
    public let id = UUID()
    public let name: String
    public let apiKey: String
    public let apiProxyAddress: String
    public var models: [LanguageModel]
    
    public init(name: String, apiKey: String, apiProxyAddress: String, models: [LanguageModel]) {
        self.name = name
        self.models = models
        self.apiKey = apiKey
        self.apiProxyAddress = apiProxyAddress
    }

     // 实现 Hashable 协议
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    public static func == (lhs: LanguageProvider, rhs: LanguageProvider) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public struct LanguageModel: Identifiable, Hashable {
    public let id: String
    public let providerName: String
    public let name: String
    public let responseHandler: (Data) throws -> String
    
    public init(
        providerName: String,
        id: String,
        name: String,
        responseHandler: @escaping (Data) throws -> String
    ) {
        self.providerName = providerName
        self.id = id
        self.name = name
        self.responseHandler = responseHandler
    }
    
    // 实现 Hashable 协议
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(providerName)
        hasher.combine(name)
    }
    
    // 实现 Equatable 协议（Hashable 需要）
    public static func == (lhs: LanguageModel, rhs: LanguageModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.providerName == rhs.providerName &&
               lhs.name == rhs.name
    }
}
struct ChatModelSettings {
    var provider: String
    var model: String
    var apiProxyAddress: String
    var apiKey: String
    var extra: [String: String]
}

public class LLMService {
    private let value: ChatModelSettings
    private let model: LanguageModel
    private let prompt: String
    private var messages: [Message]
    
    init(value: ChatModelSettings, prompt: String = "") {
        self.value = value
        self.model = LLMServiceProviders.first(where: { $0.name == value.provider })?.models.first(where: { $0.name == value.model }) ?? LLMServiceProviders.first?.models.first ?? LanguageModel(providerName: "", id: "", name: "", responseHandler: DefaultHandler)
        self.prompt = prompt
        self.messages = [Message(role: "system", content: prompt)]
    }
    
    public func chat(content: String) async throws -> String {
        // 添加用户消息
        let userMessage = Message(role: "user", content: content)
        messages.append(userMessage)
        
        // 创建URL请求
        guard let url = URL(string: value.apiProxyAddress) else {
            throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 使用累积的消息历史
        let requestBody = ChatRequest(
            model: value.model,
            messages: messages,
            format: "json",
            stream: false
        )
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(value.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 编码请求体
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            // 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            // 检查状态码
            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "API request failed: HTTP \(httpResponse.statusCode)"])
            }
            
            // 打印原始响应
            print("Original response: \(String(data: data, encoding: .utf8) ?? "")")
            
            // 使用模型的响应处理器处理响应
            let result = try model.responseHandler(data)
            
            // 添加助手响应到消息历史
            let assistantMessage = Message(role: "assistant", content: result)
            messages.append(assistantMessage)
            
            return result
            
        } catch {
            throw error
        }
    }
    
    // 添加获取消息历史的方法
    public func getMessages() -> [Message] {
        return messages
    }
}


public struct DefaultChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    public let systemFingerprint: String
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
    }
    
    public struct Choice: Codable {
        public let index: Int
        public let message: Message
        public let logprobs: String?
        public let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message, logprobs
            case finishReason = "finish_reason"
        }
    }
    
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    
    public struct Usage: Codable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        public let promptTokensDetails: PromptTokensDetails
        public let promptCacheHitTokens: Int
        public let promptCacheMissTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case promptCacheHitTokens = "prompt_cache_hit_tokens"
            case promptCacheMissTokens = "prompt_cache_miss_tokens"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
}

public struct DeepseekChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    public let systemFingerprint: String
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
    }
    
    public struct Choice: Codable {
        public let index: Int
        public let message: Message
        public let logprobs: String?
        public let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message, logprobs
            case finishReason = "finish_reason"
        }
    }
    
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    
    public struct Usage: Codable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        public let promptTokensDetails: PromptTokensDetails
        public let promptCacheHitTokens: Int
        public let promptCacheMissTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case promptCacheHitTokens = "prompt_cache_hit_tokens"
            case promptCacheMissTokens = "prompt_cache_miss_tokens"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
}

public struct DoubaoChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    
    public struct Choice: Codable {
        public let finishReason: String
        public let index: Int
        public let logprobs: String?
        public let message: Message
        
        enum CodingKeys: String, CodingKey {
            case finishReason = "finish_reason"
            case index, logprobs, message
        }
    }
    
    public struct Message: Codable {
        public let content: String
        public let role: String
    }
    
    public struct Usage: Codable {
        public let completionTokens: Int
        public let promptTokens: Int
        public let totalTokens: Int
        public let promptTokensDetails: PromptTokensDetails
        public let completionTokensDetails: CompletionTokensDetails
        
        enum CodingKeys: String, CodingKey {
            case completionTokens = "completion_tokens"
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case completionTokensDetails = "completion_tokens_details"
        }
    }
    
    public struct PromptTokensDetails: Codable {
        public let cachedTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }
    
    public struct CompletionTokensDetails: Codable {
        public let reasoningTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case reasoningTokens = "reasoning_tokens"
        }
    }
}

public struct ChatResponse: Codable {
    public let reply: String
    
    public init(reply: String) {
        self.reply = reply
    }
}

public let DefaultHandler: ResponseHandler = { data in
    let decoder = JSONDecoder()
    let response = try decoder.decode(DefaultChatResponse.self, from: data)
    return response.choices[0].message.content
}

public let LLMServiceProviders = [
    LanguageProvider(
        name: "deepseek",
        apiKey: "",
        apiProxyAddress: "https://api.deepseek.com/chat/completions",
        models: [
                    LanguageModel(
                        providerName: "deepseek",
                        id: "deepseek-chat",
                        name: "deepseek-chat",
                        responseHandler: { data in
                            let decoder = JSONDecoder()
                            let response = try decoder.decode(DeepseekChatResponse.self, from: data)
                            return response.choices[0].message.content
                        }
                    )
                ]
            ),
            LanguageProvider(
                name: "doubao",
                apiKey: "",
                apiProxyAddress: "",
                models: [
                    LanguageModel(
                        providerName: "doubao",
                        id: "ep-20250205141518-nvl9p",
                        name: "ep-20250205141518-nvl9p",
                        responseHandler: { data in
                            let decoder = JSONDecoder()
                            let response = try decoder.decode(DoubaoChatResponse.self, from: data)
                            return response.choices[0].message.content
                        }
                    )
                ]
            )]
