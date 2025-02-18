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

public struct LanguageModel {
    public let providerName: String
    public let id: String
    public let name: String
    public let apiKey: String
    public let apiProxyAddress: String
    public var extraParams: [String: Any]?
    public let responseHandler: ResponseHandler
    
    public init(
        providerName: String,
        id: String,
        name: String,
        apiKey: String,
        apiProxyAddress: String,
        extraParams: [String: Any]? = nil,
        responseHandler: @escaping ResponseHandler
    ) {
        self.providerName = providerName
        self.id = id
        self.name = name
        self.apiKey = apiKey
        self.apiProxyAddress = apiProxyAddress
        self.extraParams = extraParams
        self.responseHandler = responseHandler
    }
}

public class LLMService {
    private let model: LanguageModel
    private let prompt: String
    
    public init(model: LanguageModel, prompt: String = "") {
        self.model = model
        self.prompt = prompt
    }
    
    public func chat(content: String) async throws -> String {
        // 创建URL请求
        guard let url = URL(string: model.apiProxyAddress) else {
            throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 构建请求消息
        let messages = [
            Message(role: "system", content: prompt),
            Message(role: "user", content: content)
        ]
        
        // 构建请求体
        let requestBody = ChatRequest(
            model: model.name,
            messages: messages,
            format: "json",
            stream: false
        )
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(model.apiKey)", forHTTPHeaderField: "Authorization")
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
            return try model.responseHandler(data)
            
        } catch {
            throw error
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

public struct ChatResponse: Codable {
    public let reply: String
    
    public init(reply: String) {
        self.reply = reply
    }
}
