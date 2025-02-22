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
    public var id: String { name }
    public let name: String
    public let logo_uri: String
    public let apiKey: String
    public let apiProxyAddress: String
    public var models: [LanguageModel]
    public let responseHandler: (Data) throws -> String
    
    public init(name: String, logo_uri: String, apiKey: String, apiProxyAddress: String, models: [LanguageModel], responseHandler: @escaping (Data) throws -> String = DefaultHandler) {
        self.name = name
        self.logo_uri = logo_uri
        self.models = models
        self.apiKey = apiKey
        self.apiProxyAddress = apiProxyAddress
        self.responseHandler = responseHandler
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
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    // 实现 Hashable 协议
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    // 实现 Equatable 协议（Hashable 需要）
    public static func == (lhs: LanguageModel, rhs: LanguageModel) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public struct LLMValues {
    public var provider: String
    public var model: String
    public var apiProxyAddress: String?
    public var apiKey: String?
    public var extra: [String: Any]
    
    // 添加公共初始化器
    public init(provider: String, model: String, apiProxyAddress: String?, apiKey: String?, extra: [String: Any] = [:]) {
        self.provider = provider
        self.model = model
        self.apiProxyAddress = apiProxyAddress
        self.apiKey = apiKey
        self.extra = extra
    }
}

public class LLMService: ObservableObject {
    @Published public var value: LLMValues
    private var provider: LanguageProvider
    private var model: LanguageModel
    private var prompt: String
    private var messages: [Message]
    
    // 添加一个属性来存储当前的数据任务
    private var currentTask: URLSessionDataTask?
    
    public init(value: LLMValues, prompt: String = "") {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.name == value.provider }) ?? LanguageProvider(name: "", logo_uri: "", apiKey: "", apiProxyAddress: "", models: [], responseHandler: DefaultHandler)
        self.model = provider.models.first(where: { $0.name == value.model }) ?? LanguageModel(id: "", name: "")
        self.prompt = prompt
        self.messages = [Message(role: "system", content: prompt)]

        print("[Package]LLM init: \(value.provider) \(value.model) \(prompt)")
    }

    public func update(value: LLMValues) {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.name == value.provider }) ?? LanguageProvider(name: "", logo_uri: "", apiKey: "", apiProxyAddress: "", models: [], responseHandler: DefaultHandler)
        self.model = provider.models.first(where: { $0.name == value.model }) ?? LanguageModel(id: "", name: "")
    }

    public func fakeChat(content: String) async throws -> String {
        // 延迟2秒 (2000000000 纳秒 = 2秒)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "This is a fake response for: \(content)"
    }
    
    public func chat(content: String) async throws -> String {
        // 添加用户消息
        let userMessage = Message(role: "user", content: content)
        messages.append(userMessage)
        
        let apiProxyAddress = value.apiProxyAddress ?? provider.apiProxyAddress
        let apiKey = value.apiKey ?? provider.apiKey
        print("[Package]LLM chat: \(model.name) \(apiProxyAddress) \(apiKey)")

        // 创建URL请求
        guard let url = URL(string: apiProxyAddress) else {
            throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 使用累积的消息历史
        let requestBody = ChatRequest(
            model: model.name,
            messages: messages,
            format: "json",
            stream: false
        )
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
            let result = try self.provider.responseHandler(data)
            
            // 添加助手响应到消息历史
            let assistantMessage = Message(role: "assistant", content: result)
            messages.append(assistantMessage)
            
            return result
            
        } catch {
            throw error
        }
    }

    // 添加取消方法
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    public func chatStream(content: String) async throws -> AsyncThrowingStream<String, Error> {
        // 添加用户消息
        let userMessage = Message(role: "user", content: content)
        messages.append(userMessage)
        
        let apiProxyAddress = value.apiProxyAddress ?? provider.apiProxyAddress
        let apiKey = value.apiKey ?? provider.apiKey
        print("[Package]LLM chatStream: \(model.name) \(apiProxyAddress) \(apiKey)")

        guard let url = URL(string: apiProxyAddress) else {
            throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let requestBody = ChatRequest(
            model: model.name,
            messages: messages,
            format: "json",
            stream: true
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return AsyncThrowingStream { continuation in
            // Declare task as a variable first
            var task: URLSessionDataTask?
            
            task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Store task reference
                self.currentTask = task
                
                // 检查是否被取消
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    continuation.finish()
                    return
                }
                
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "API request failed: HTTP \(httpResponse.statusCode)"]))
                    return
                }
                
                guard let data = data else {
                    continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }
                
                // 处理 SSE 格式的响应
                let responseText = String(decoding: data, as: UTF8.self)
                let lines = responseText.components(separatedBy: "\n")
                
                var fullContent = ""
                
                for line in lines {
                    guard !line.isEmpty else { continue }
                    
                    if line == "data: [DONE]" {
                        // 流结束时，将完整内容添加到消息历史
                        let assistantMessage = Message(role: "assistant", content: fullContent)
                        self.messages.append(assistantMessage)
                        continuation.finish()
                        return
                    }
                    
                    guard line.hasPrefix("data: ") else { continue }
                    
                    let jsonString = String(line.dropFirst(6))
                    do {
                        if let jsonData = jsonString.data(using: .utf8),
                           let response = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let choices = response["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            fullContent += content
                            continuation.yield(content)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        continue
                    }
                }
            }
            
            // Start the task
            task?.resume()
            
            continuation.onTermination = { @Sendable _ in
                task?.cancel()
                self.currentTask = nil
            }
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
        name: "openai",
        logo_uri: "provider_dark_openai",
        apiKey: "",
        apiProxyAddress: "https://api.openai.com/v1",
        models: [
            LanguageModel(
                id: "gpt-4o-mini",
                name: "gpt-4o-mini"
            ),
            LanguageModel(
                id: "gpt-4o",
                name: "gpt-4o"
            )
        ],
        responseHandler: DefaultHandler

    ),
    LanguageProvider(
        name: "deepseek",
        logo_uri: "provider_dark_deepseek",
        apiKey: "",
        apiProxyAddress: "https://api.deepseek.com/chat/completions",
        models: [
            LanguageModel(
                id: "deepseek-chat",
                name: "deepseek-chat"
            ),
            LanguageModel(
                id: "deepseek-r1",
                name: "deepseek-r1"
            )
        ],
        responseHandler: DefaultHandler
    ),
    LanguageProvider(
        name: "doubao",
        logo_uri: "provider_dark_doubao",
        apiKey: "",
        apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
        models: [
            LanguageModel(
                id: "ep-20250205141518-nvl9p",
                name: "ep-20250205141518-nvl9p"
            )
        ],
        responseHandler: { data in
            let decoder = JSONDecoder()
            let response = try decoder.decode(DoubaoChatResponse.self, from: data)
            return response.choices[0].message.content
        }
    )
]
