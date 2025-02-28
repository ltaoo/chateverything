import Foundation

public struct LLMServiceMessage: Codable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct LLMServiceRequest: Codable {
    public let model: String
    public let messages: [LLMServiceMessage]
    public let format: String
    public let stream: Bool
    
    public init(model: String, messages: [LLMServiceMessage], format: String, stream: Bool) {
        self.model = model
        self.messages = messages
        self.format = format
        self.stream = stream
    }
}

public typealias LLMServiceResponseHandler = (Data) throws -> String
public class LLMServiceEvents {
    public let onStart: () -> Void
    public let onChunk: (String) -> Void
    public let onFinish: (String) -> Void
    public let onError: (Error) -> Void

    public init(onStart: @escaping () -> Void, onChunk: @escaping (String) -> Void, onFinish: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.onStart = onStart
        self.onChunk = onChunk
        self.onFinish = onFinish
        self.onError = onError
    }
}

public struct LLMProvider: Identifiable, Hashable {
    public var id: String
    public let name: String
    public let logo_uri: String
    public let apiKey: String
    public let apiProxyAddress: String
    public var models: [LLMProviderModel]
    public let responseHandler: (Data) throws -> String

    static func Default() -> LLMProvider {
        return LLMProvider(
            id: "openai",
            name: "openai",
            logo_uri: "provider_light_openai",
            apiKey: "",
            apiProxyAddress: "https://api.openai.com/v1",
            models: [
                LLMProviderModel(
                    id: "gpt-4o-mini",
                    name: "gpt-4o-mini",
                    desc: "",
                    type: "",
                    tags: []
                )
            ],
            responseHandler: LLMServiceDefaultHandler
        )
    }

    public init(id: String, name: String, logo_uri: String, apiKey: String, apiProxyAddress: String, models: [LLMProviderModel], responseHandler: @escaping (Data) throws -> String = LLMServiceDefaultHandler) {
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
    public let desc: String
    // 类型 对话、视频、音频、图片
    public let type: String
    // 标签 
    public let tags: [String]

    static func Default() -> LLMProviderModel {
        return LLMProviderModel(
            id: "gpt-4o-mini",
            name: "gpt-4o-mini",
            desc: "gpt-4o-mini",
            type: "对话",
            tags: []
        )
    }
    public init(id: String, name: String, desc: String, type: String, tags: [String]) {
        self.id = id
        self.name = name
        self.desc = desc
        self.type = type
        self.tags = tags
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
    public var events: LLMServiceEvents?
    
    // 添加一个属性来存储当前的数据任务
    private var currentTask: URLSessionDataTask?
    
    // Add new callback type
    public typealias ChatCallback = (String) -> Void
    
    public init(value: LLMServiceConfig) {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.id == value.provider }) ?? LLMProvider.Default()
        self.model = provider.models.first(where: { $0.id == value.model }) ?? LLMProviderModel.Default()
        // self.prompt = prompt
        // self.messages = [Message(role: "system", content: prompt)]

        print("[Package]LLM init: \(value.provider) \(value.model) \(value.apiProxyAddress) \(value.apiKey)")
    }

    public func setEvents(events: LLMServiceEvents) {
        self.events = events
    }

    public func update(value: LLMServiceConfig) {
        self.value = value
        self.provider = LLMServiceProviders.first(where: { $0.id == value.provider }) ?? LLMProvider.Default()
        self.model = provider.models.first(where: { $0.id == value.model }) ?? LLMProviderModel.Default()
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

    public func chat(messages: [LLMServiceMessage]) -> AsyncThrowingStream<String, Error> {
        print("[Package]LLM chat: \(messages)")

        let stream = self.value.extra["stream"] as? Bool ?? false
        
        return AsyncThrowingStream { continuation in
            let apiProxyAddress = self.value.apiProxyAddress ?? provider.apiProxyAddress
            let apiKey = self.value.apiKey ?? provider.apiKey
            print("[Package]LLM chat: \(self.value.provider) \(self.value.model) \(apiProxyAddress) \(apiKey) \(stream)")

            self.events?.onStart()

            guard let url = URL(string: apiProxyAddress) else {
                self.events?.onError(NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                return
            }
            
            let requestBody = LLMServiceRequest(
                model: self.value.model,
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
                            self.events?.onError(NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                            continuation.finish(throwing: NSError(domain: "", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                            return
                        }
                        
                        for try await byte in bytes {
                            if Task.isCancelled {
                                self.events?.onFinish(fullContent)
                                continuation.finish()
                                return
                            }
                            
                            self.events?.onChunk(String(bytes: [byte], encoding: .utf8) ?? "")
                            buffer += String(bytes: [byte], encoding: .utf8) ?? ""
                            
                            if buffer.contains("\n") {
                                let lines = buffer.components(separatedBy: "\n")
                                buffer = lines.last ?? ""  // Keep the incomplete line
                                
                                for line in lines.dropLast() where !line.isEmpty {
                                    if line == "data: [DONE]" {
                                        // let assistantMessage = Message(role: "assistant", content: fullContent)
                                        // self.messages.append(assistantMessage)
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
                        self.events?.onError(error)
                        continuation.finish(throwing: error)
                    }
                }
            } else {
                request.timeoutInterval = 30 // 设置30秒超时
                // 非流式响应
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    do {
                        if let error = error {
                            self.events?.onError(error)
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
                        
                        // let assistantMessage = Message(role: "assistant", content: result)
                        // self.messages.append(assistantMessage)
                        
                        self.events?.onFinish(result)
                        continuation.yield(result)
                        continuation.finish()
                    } catch {
                        self.events?.onError(error)
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
}

public let LLMServiceDefaultHandler: LLMServiceResponseHandler = { data in
    let decoder = JSONDecoder()
    let response = try decoder.decode(DefaultChatResponse.self, from: data)
    return response.choices[0].message.content
}

public let LLMServiceProviders: [LLMProvider] = [
    LLMProvider(
        id: "openai",
        name: "openai",
        logo_uri: "provider_light_openai",
        apiKey: "",
        apiProxyAddress: "https://api.openai.com/v1",
        models: [
            LLMProviderModel(
                id: "gpt-4o-mini",
                name: "gpt-4o-mini",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "gpt-4o",
                name: "gpt-4o",
                desc: "",
                type: "对话",
                tags: []
            )
        ],
        responseHandler: LLMServiceDefaultHandler

    ),
    LLMProvider(
        id: "deepseek",
        name: "deepseek",
        logo_uri: "provider_light_deepseek",
        apiKey: "",
        apiProxyAddress: "https://api.deepseek.com/chat/completions",
        models: [
            LLMProviderModel(
                id: "deepseek-chat",
                name: "deepseek-chat",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "deepseek-r1",
                name: "deepseek-r1",
                desc: "",
                type: "对话",
                tags: []
            )
        ],
        responseHandler: LLMServiceDefaultHandler
    ),
    LLMProvider(
        id: "doubao",
        name: "火山引擎",
        logo_uri: "provider_dark_doubao",
        apiKey: "",
        apiProxyAddress: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
        models: [
            LLMProviderModel(
                id: "doubao-1-5-pro-32k-250115",
                name: "doubao-1.5-pro",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "doubao-1-5-lite-32k-250115",
                name: "doubao-1.5-lite",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "deepseek-v3-241226",
                name: "deepseek-v3",
                desc: "",
                type: "对话",
                tags: []
            )
        ],
        responseHandler: { data in
            let decoder = JSONDecoder()
            let response = try decoder.decode(DoubaoChatResponse.self, from: data)
            return response.choices[0].message.content
        }
    ),
    LLMProvider(
        id: "siliconflow",
        name: "硅基流动",
        logo_uri: "provider_light_siliconcloud",
        apiKey: "",
        apiProxyAddress: "https://api.siliconflow.cn/v1/chat/completions",
        models: [
            LLMProviderModel(
                id: "Pro/deepseek-ai/DeepSeek-R1",
                name: "Pro/deepseek-ai/DeepSeek-R1",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "Pro/deepseek-ai/DeepSeek-V3",
                name: "Pro/deepseek-ai/DeepSeek-V3",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "deepseek-ai/DeepSeek-R1",
                name: "deepseek-ai/DeepSeek-R1",
                desc: "",
                type: "对话",
                tags: []
            ),
            LLMProviderModel(
                id: "deepseek-ai/DeepSeek-V3",
                name: "deepseek-ai/DeepSeek-V3",
                desc: "",
                type: "对话",
                tags: []
            )
        ],
        responseHandler: LLMServiceDefaultHandler
    ),
]

