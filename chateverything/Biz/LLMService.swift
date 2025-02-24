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

public typealias ResponseHandler = (Data) throws -> String

public struct LLMProvider: Identifiable, Hashable {
    public var id: String
    public let name: String
    public let logo_uri: String
    public let apiKey: String
    public let apiProxyAddress: String
    public var models: [LLMProviderModel]
    public let responseHandler: (Data) throws -> String
    
    public init(id: String, name: String, logo_uri: String, apiKey: String, apiProxyAddress: String, models: [LLMProviderModel], responseHandler: @escaping (Data) throws -> String = DefaultHandler) {
        self.id = id
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
    public static func == (lhs: LLMProvider, rhs: LLMProvider) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public struct LLMProviderModel: Identifiable, Hashable {
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
    public static func == (lhs: LLMProviderModel, rhs: LLMProviderModel) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public struct LLMServiceConfig {
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
    @Published public var value: LLMServiceConfig
    private var provider: LLMProvider
    private var model: LLMProviderModel
    private var prompt: String
    private var messages: [Message]
    
    // 添加一个属性来存储当前的数据任务
    private var currentTask: URLSessionDataTask?
    
    // Add new callback type
    public typealias ChatCallback = (String) -> Void
    
    public init(value: LLMServiceConfig, prompt: String = "") {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.name == value.provider }) ?? LLMProvider(id: "", name: "", logo_uri: "", apiKey: "", apiProxyAddress: "", models: [], responseHandler: DefaultHandler)
        self.model = provider.models.first(where: { $0.name == value.model }) ?? LLMProviderModel(id: "", name: "")
        self.prompt = prompt
        self.messages = [Message(role: "system", content: prompt)]

        print("[Package]LLM init: \(value.provider) \(value.model) \(prompt)")
    }

    public func update(value: LLMServiceConfig) {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.name == value.provider }) ?? LLMProvider(id: "", name: "", logo_uri: "", apiKey: "", apiProxyAddress: "", models: [], responseHandler: DefaultHandler)
        self.model = provider.models.first(where: { $0.name == value.model }) ?? LLMProviderModel(id: "", name: "")
    }

    public func fakeChat(content: String) async throws -> String {
        // 延迟2秒 (2000000000 纳秒 = 2秒)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "This is a fake response for: \(content)"
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    
    public func chat(content: String) -> AsyncThrowingStream<String, Error> {
        let stream = value.extra["stream"] as? Bool ?? false
        
        return AsyncThrowingStream { continuation in
            // Add user message
            let userMessage = Message(role: "user", content: content)
            messages.append(userMessage)
            
            let apiProxyAddress = value.apiProxyAddress ?? provider.apiProxyAddress
            let apiKey = value.apiKey ?? provider.apiKey
            print("[Package]LLM chat: \(model.name) \(apiProxyAddress) \(apiKey) \(stream)")

            guard let url = URL(string: apiProxyAddress) else {
                continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                return
            }
            
            let requestBody = ChatRequest(
                model: model.name,
                messages: messages,
                format: "text",
                stream: stream
            )
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(requestBody)
            } catch {
                continuation.finish(throwing: error)
                return
            }

            if stream {
                Task {
                    var buffer = ""
                    var fullContent = ""
                    
                    do {
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                        }
                        
                        for try await byte in bytes {
                            if Task.isCancelled {
                                continuation.finish()
                                return
                            }
                            
                            buffer += String(bytes: [byte], encoding: .utf8) ?? ""
                            
                            if buffer.contains("\n") {
                                let lines = buffer.components(separatedBy: "\n")
                                buffer = lines.last ?? ""  // Keep the incomplete line
                                
                                for line in lines.dropLast() where !line.isEmpty {
                                    if line == "data: [DONE]" {
                                        let assistantMessage = Message(role: "assistant", content: fullContent)
                                        self.messages.append(assistantMessage)
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if line.hasPrefix("data: ") {
                                        let jsonString = String(line.dropFirst(6))
                                        if let jsonData = jsonString.data(using: .utf8),
                                           let response = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                           let choices = response["choices"] as? [[String: Any]],
                                           let delta = choices.first?["delta"] as? [String: Any],
                                           let content = delta["content"] as? String {
                                            
                                            fullContent += content
                                            continuation.yield(fullContent)  // Only yield the new content
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            } else {
                // 非流式响应
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    do {
                        if let error = error {
                            continuation.finish(throwing: error)
                            return
                        }
                        
                        guard let data = data,
                              let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                            return
                        }
                        
                        let result = try self.provider.responseHandler(data)
                        
                        let assistantMessage = Message(role: "assistant", content: result)
                        self.messages.append(assistantMessage)
                        
                        continuation.yield(result)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                task.resume()
            }
            
            continuation.onTermination = { @Sendable _ in
                self.currentTask?.cancel()
            }
        }
    }

    // 添加获取消息历史的方法
    public func getMessages() -> [Message] {
        return messages
    }
}

public let DefaultHandler: ResponseHandler = { data in
    let decoder = JSONDecoder()
    let response = try decoder.decode(DefaultChatResponse.self, from: data)
    return response.choices[0].message.content
}

public let LLMServiceProviders = [
    LLMProvider(
        id: "openai",
        name: "openai",
        logo_uri: "provider_dark_openai",
        apiKey: "",
        apiProxyAddress: "https://api.openai.com/v1",
        models: [
            LLMProviderModel(
                id: "gpt-4o-mini",
                name: "gpt-4o-mini"
            ),
            LLMProviderModel(
                id: "gpt-4o",
                name: "gpt-4o"
            )
        ],
        responseHandler: DefaultHandler

    ),
    LLMProvider(
        id: "deepseek",
        name: "deepseek",
        logo_uri: "provider_dark_deepseek",
        apiKey: "",
        apiProxyAddress: "https://api.deepseek.com/chat/completions",
        models: [
            LLMProviderModel(
                id: "deepseek-chat",
                name: "deepseek-chat"
            ),
            LLMProviderModel(
                id: "deepseek-r1",
                name: "deepseek-r1"
            )
        ],
        responseHandler: DefaultHandler
    ),
    LLMProvider(
        id: "doubao",
        name: "doubao",
        logo_uri: "provider_dark_doubao",
        apiKey: "",
        apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
        models: [
            LLMProviderModel(
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

