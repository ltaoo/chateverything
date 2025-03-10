import CoreData
import Foundation

protocol RoleResponseHandler {
    func start(
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config
    )
    func handle(
        text: String,
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config,
        completion: (([ChatBoxBiz]) -> Void)?
    )
}

class DefaultRoleResponseHandler: RoleResponseHandler {
    public func start(
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config
    ) {
    }
    public func handle(
        text: String,
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config,
        completion: (([ChatBoxBiz]) -> Void)?
    ) {
        let loadingMessage = ChatBoxBiz(
            id: UUID(),
            type: "message",
            created_at: Date(),
            isMe: false,
            payload_id: UUID(),
            session_id: session.id,
            sender_id: role.id,
            payload: ChatPayload.message(ChatTextMsgBiz(text: "", nodes: [])),
            loading: true
        )
        DispatchQueue.main.async {
            session.appendTmpBox(box: loadingMessage)
        }
        print("[BIZ]RoleBiz before chat 1 \(role.config.autoBlur)")
        let isStream = role.config.stream
        var initial: ChatBoxBiz? = nil
        let events = LLMServiceEvents(
            onStart: {
                print("[BIZ]RoleBiz onStart")
            },
            onChunk: { chunk in
                print("[BIZ]RoleBiz onChunk: \(chunk)")
                guard isStream else {
                    return
                }
                guard let box = initial else {
                    session.removeLastBox()
                    let data = ChatTextMsgBiz(text: chunk, nodes: [])
                    print("before set data blurred1 \(role.config.autoBlur)")
                    data.blurred = role.config.autoBlur
                    let payload = ChatPayload.message(data)
                    initial = ChatBoxBiz(
                        id: UUID(),
                        type: "message",
                        created_at: Date(),
                        isMe: false,
                        payload_id: UUID(),
                        session_id: session.id,
                        sender_id: role.id,
                        payload: payload,
                        loading: false
                    )
                    data.setSender(role, config)
                    session.appendTmpBox(box: initial!)
                    return
                }
                if case let ChatPayload.message(msg) = box.payload! {
                    DispatchQueue.main.async {
                        msg.text = chunk
                    }
                }
                // box.updateTmpPayload(
                //     payload: ChatPayload.message(ChatTextMsgBiz(text: chunk, nodes: [])), store: config.store
                // )
            },
            onFinish: { result in
                print("[BIZ]RoleBiz onFinish: \(result) \(role.config.autoBlur)")
                guard isStream else {

                    DispatchQueue.main.async {
                        session.removeLastBox()
                        let box = ChatBoxBiz(
                            id: UUID(),
                            type: "message",
                            created_at: Date(),
                            isMe: false,
                            payload_id: UUID(),
                            session_id: session.id,
                            sender_id: role.id,
                            payload: ChatPayload.message(ChatTextMsgBiz(text: result, nodes: [])),
                            loading: false
                        )
                        session.appendBox(box: box)
                    }
                    if let tts = role.tts, role.config.autoSpeak {
                        tts.speak(result)
                    }
                    return
                }
                guard let box = initial else {
                    return
                }
                box.save(sessionId: session.id, store: config.store)
                if let tts = role.tts, role.config.autoSpeak {
                    tts.speak(result)
                }
            },
            onError: { error in
                print("[BIZ]RoleBiz onError: \(error)")
                DispatchQueue.main.async {
                    session.removeLastBox()
                    let box = ChatBoxBiz(
                        id: UUID(),
                        type: "error",
                        created_at: Date(),
                        isMe: false,
                        payload_id: UUID(),
                        session_id: session.id,
                        sender_id: role.id,
                        payload: ChatPayload.error(
                            ChatErrorMsgBiz(error: error.localizedDescription)),
                        loading: false
                    )
                    session.appendBox(box: box)
                }
            })
        role.llm?.setEvents(events: events)
        Task {
            guard let stream = role.llm?.chat(messages: role.buildMessagesWithText(text: text))
            else { return }
        }
    }
}

protocol RolePayloadBuilder {
    func build(
        record: BoxPayloadTypes,
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config
    ) -> ChatPayload?
}

class DefaultRolePayloadBuilder: RolePayloadBuilder {
    func build(
        record: BoxPayloadTypes,
        role: RoleBiz,
        session: ChatSessionBiz,
        config: Config
    ) -> ChatPayload? {
        print("[BIZ]DefaultRolePayloadBuilder build: \(role.name) \(role.config.autoBlur)")
        switch record {
        case BoxPayloadTypes.message(let message):
            let data = ChatTextMsgBiz(text: message.text!, nodes: [])
            let payload = ChatPayload.message(data)
            print("before set data blurred2 \(role.config.autoBlur)")
            data.blurred = role.config.autoBlur
            data.setSender(role, config)
            // data.handler.setPayload(payload)
            return payload
        case BoxPayloadTypes.audio(let audio):
            let data = ChatAudioBiz(
                text: audio.text!, nodes: [], url: audio.uri!, duration: audio.duration)
            let payload = ChatPayload.audio(data)
            print("before set data blurred3 \(role.config.autoBlur)")
            data.blurred = role.config.autoBlur
            return payload
        case BoxPayloadTypes.puzzle(let puzzle):
            let opts = puzzle.opts
            let options =
                (ChatPuzzleMsgBiz.optionsFromJSON(opts ?? "") ?? [] as! [ChatPuzzleOption])
                .map { ChatPuzzleOption(id: $0.id, text: $0.text) }
            let selected = options.first { $0.id == puzzle.answer }
            return ChatPayload.puzzle(
                ChatPuzzleMsgBiz(
                    title: puzzle.title!, options: options, answer: puzzle.answer ?? "",
                    selected: selected, corrected: false))
        case BoxPayloadTypes.image(let image):
            return ChatPayload.image(
                ChatImageMsgBiz(url: image.url!, width: image.width, height: image.height))
        case BoxPayloadTypes.video(let video):
            return ChatPayload.video(
                ChatVideoMsgBiz(
                    url: video.url!, thumbnail: video.thumbnail!, width: video.width,
                    height: video.height, duration: video.duration))
        case BoxPayloadTypes.error(let error):
            return ChatPayload.error(ChatErrorMsgBiz(error: error.error!))
        case BoxPayloadTypes.tipText(let tipText):
            return ChatPayload.tipText(ChatTipTextMsgBiz(content: tipText.content!))
        case BoxPayloadTypes.time(let time):
            return ChatPayload.time(ChatTimeMsgBiz(time: time.time!))
        case BoxPayloadTypes.dictionary(let dictionary):
            return ChatPayload.dictionary(
                ChatDictionaryMsgBiz(
                    text: dictionary.detected_lang!,
                    detected_lang: dictionary.detected_lang!,
                    target_lang: dictionary.target_lang!,
                    translation: dictionary.translation!,
                    pronunciation: dictionary.pronunciation!,
                    pronunciation_tip: dictionary.pronunciation_tip!,
                    definitions: Array.fromJSON(dictionary.definitions!),
                    examples: Array.fromJSON(dictionary.examples!),
                    text_type: dictionary.text_type!
                )
            )
        default:
            return nil
        }
    }
}

public struct RoleProps {
    var id: UUID  // 必填
    var name: String = ""
    var desc: String = ""
    var avatar: String = "avatar1"
    var prompt: String = ""
    var language: String = "en-US"
    var type: String = "chat"
    var disabled: Bool = false
    var created_at: Date = Date()
    var config: RoleConfig = RoleConfig(
        voice: defaultRoleTTS,
        llm: defaultRoleLLM,
        stream: true,
        autoSpeak: true,
        autoBlur: true)
    var responseHandler: RoleResponseHandler = DefaultRoleResponseHandler()
    var payloadBuilder: RolePayloadBuilder = DefaultRolePayloadBuilder()

    public init(id: UUID) {
        self.id = id
    }
}

public class RoleBiz: ObservableObject, Equatable, Identifiable {
    public var id: UUID
    @Published public var name: String
    @Published public var desc: String
    @Published public var avatar: String
    @Published public var prompt: String
    @Published public var language: String
    @Published public var disabled: Bool
    @Published public var created_at: Date
    @Published public var config: RoleConfig
    public var llm: LLMService?
    public var tts: TTSEngine?
    var type: String = "chat"

    @Published var noLLM = true
    @Published var loading = false
    @Published var count: Int = 0
    @Published var messages: [LLMServiceMessage] = []

    var responseHandler: RoleResponseHandler
    var payloadBuilder: RolePayloadBuilder = DefaultRolePayloadBuilder()

    public static func == (lhs: RoleBiz, rhs: RoleBiz) -> Bool {
        return lhs.id == rhs.id
    }

    static func Get(id: UUID, config: Config) -> RoleBiz? {
        let m = config.roles.first { $0.id == id }
        if let m = m {
            return m
        }
        return nil
    }
    static func Insert() {

    }

    init(props: RoleProps) {
        self.id = props.id
        self.name = props.name
        self.desc = props.desc
        self.avatar = props.avatar
        self.prompt = props.prompt
        self.messages = [LLMServiceMessage(role: "system", content: props.prompt)]
        self.language = props.language
        self.disabled = props.disabled
        self.created_at = props.created_at
        self.type = props.type
        self.config = props.config
        self.llm = nil
        self.tts = nil
        self.responseHandler = props.responseHandler
        self.payloadBuilder = props.payloadBuilder

        print("[BIZ]RoleBiz init: \(self.name) \(props.config.autoBlur)")
    }

    // Add convenience init that uses the old parameter list but creates RoleProps internally
    convenience init(
        id: UUID,
        name: String,
        desc: String,
        avatar: String,
        prompt: String,
        language: String,
        created_at: Date,
        config: RoleConfig
    ) {
        var props = RoleProps(id: id)
        props.name = name
        props.desc = desc
        props.avatar = avatar
        props.prompt = prompt
        props.language = language
        props.created_at = created_at
        props.config = config
        self.init(props: props)
    }

    static func from(_ entity: Role, config: Config) -> RoleBiz? {
        let id = entity.id ?? UUID()
        let config_str = entity.config ?? ""

        var props = RoleProps(id: id)
        props.name = entity.name ?? ""
        props.avatar = entity.avatar_uri ?? ""
        props.prompt = entity.prompt ?? ""
        props.created_at = entity.created_at ?? Date()

        // 解析 config JSON
        var voice = defaultRoleTTS
        var llmHelper = defaultRoleLLM

        props.config = RoleConfig(voice: voice, llm: llmHelper)

        return RoleBiz(props: props)
    }

    func updateLLM(config: Config) {
        self.noLLM = false
        var llm: LLMService? = nil

        let llmConfig = self.config.llm
        print("[BIZ]RoleBiz updateLLM \(llmConfig["provider"]) \(llmConfig["model"])")
        let llmProviderController = config.llmProviderControllers.first {
            $0.id == llmConfig["provider"] as? String
        }
        if let llmProviderController = llmProviderController {
            var value = llmProviderController.build(config: self.config)
            value.extra["stream"] = self.config.stream
            // print(
            //     "[BIZ]RoleBiz updateLLM value: \(value.provider) \(value.model) \(value.apiProxyAddress) \(value.apiKey)"
            // )
            llm = LLMService(value: value)
        }
        if llm == nil {
            self.noLLM = true
        }
        self.llm = llm
    }
    func updateTTS(config: Config) {
        var ttsConfig = self.config.voice
        print("[BIZ]RoleBiz updateTTS \(ttsConfig["provider"])")
        let controller = config.ttsProviderControllers.first {
            $0.id == ttsConfig["provider"] as? String
        }
        guard let controller = controller else {
            return
        }
        let tts: TTSEngine = {
            switch ttsConfig["provider"] as? String {
            case "tencent":
                return TencentTTSEngine()
            case "system":
                return SystemTTSEngine()
            default:
                return SystemTTSEngine()
            }
        }()
        for (k, v) in controller.value.credential {
            ttsConfig[k] = v
        }
        tts.setConfig(config: ttsConfig)
        // print("[BIZ]RoleBiz updateTTS before set tts")
        self.tts = tts
    }
    func setMessages(messages: [LLMServiceMessage]) {
        self.messages = messages
    }
    func appendMessages(messages: [LLMServiceMessage?]) {
        self.messages = self.messages + messages.compactMap { $0 }
    }
    func buildMessagesWithText(text: String) -> [LLMServiceMessage] {
        messages.append(LLMServiceMessage(role: "user", content: text))
        return messages
    }

    func load(config: Config) {
        print("[BIZ]RoleBiz load \(self.id) \(self.config.autoBlur)")
        // let m = config.roles.first { $0.id == self.id }
        let m = self
        // guard let m = m else {
        //     print("[BIZ]RoleBiz load error: role not found \(self.id)")
        //     self.loading = false
        //     return
        // }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.name = m.name
            self.desc = m.desc
            self.avatar = m.avatar
            self.prompt = m.prompt
            self.language = m.language
            self.created_at = m.created_at
            self.config = m.config
            if m.id != config.me.id {
                self.updateLLM(config: config)
                self.updateTTS(config: config)
            }
            print(
                "[BIZ]RoleBiz complete load \(self.id) \(self.config.autoBlur) \(m.name) \(m.config.autoBlur)"
            )
            self.loading = false  // 移到最后，确保所有数据都加载完成
        }
    }

    func cancel() {
        self.llm?.cancel()
    }

    func start(session: ChatSessionBiz, config: Config) {
        if self.llm == nil {
            self.updateLLM(config: config)
        }
        responseHandler.start(role: self, session: session, config: config)
    }
    func response(
        text: String, session: ChatSessionBiz, config: Config,
        completion: (([ChatBoxBiz]) -> Void)? = nil
    ) {
        if self.llm == nil {
            self.updateLLM(config: config)
        }

        guard self.llm != nil else {
            let box = ChatBoxBiz(
                id: UUID(),
                type: "error",
                created_at: Date(),
                isMe: false,
                payload_id: UUID(),
                session_id: session.id,
                sender_id: self.id,
                payload: ChatPayload.error(ChatErrorMsgBiz(error: "请先配置语言模型")),
                loading: false
            )
            completion?([box])
            return
        }

        responseHandler.handle(
            text: text, role: self, session: session, config: config, completion: completion)
    }
}

public struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

public enum SwiftValueType {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([SwiftValueType])
    case dictionary([String: SwiftValueType])
}

// Replace the RoleConfig struct with this implementation
public class RoleConfig {
    public var voice: [String: Any]
    public var llm: [String: Any]
    public var stream: Bool = true
    public var autoSpeak: Bool = true
    public var autoBlur: Bool = true

    public init(
        voice: [String: Any], llm: [String: Any], stream: Bool = true, autoSpeak: Bool = true,
        autoBlur: Bool = true
    ) {
        self.voice = voice
        self.llm = llm
        self.stream = stream
        self.autoSpeak = autoSpeak
        self.autoBlur = autoBlur
    }

    public func updateLLM(model: String) {
        self.llm["model"] = model
    }
    public func updateVoice(value: [String: Any]) {
        self.voice = value
    }
    public func updateAutoSpeak(value: Bool) {
        self.autoSpeak = value
    }
    public func updateAutoBlur(value: Bool) {
        self.autoBlur = value
    }
}

public class RoleLLMHelper: Codable {
    public var provider: String
    public var model: String
    public var stream: Bool = false
    public var json: Bool = false

    public init(provider: String, model: String, stream: Bool = false, json: Bool = false) {
        self.provider = provider
        self.model = model
        self.stream = stream
        self.json = json
    }

    func build(config: Config) -> LLMServiceConfig? {
        let provider_id = self.provider
        let model_id = self.model
        let values = config.llmProviderControllers.first { $0.id == provider_id }

        for v in config.llmProviderControllers {
            print(
                "[BIZ]RoleLLMHelper build provider: \(v.id) \(v.value.apiProxyAddress) \(v.provider.apiProxyAddress) \(v.value.apiKey)"
            )
        }

        guard let values = values else {
            return nil
        }

        print(
            "[BIZ]RoleLLMHelper build provider: \(values.id) \(values.value.apiProxyAddress) \(values.provider.apiProxyAddress) \(values.value.apiKey)"
        )

        let model = values.models.first { $0.id == model_id }

        guard let model = model else {
            return nil
        }

        return LLMServiceConfig(
            provider: values.id,
            model: model.id,
            apiProxyAddress: values.value.apiProxyAddress ?? values.provider.apiProxyAddress,
            apiKey: values.value.apiKey,
            extra: [
                "stream": self.stream,
                "json": self.json,
            ]
        )
    }
}

public class RoleVoice: ObservableObject, Codable {
    // 引擎，目前支持 QCloud、System
    @Published var engine: String
    // 语速
    @Published var rate: Double
    // 音量
    @Published var volume: Double
    // 情感表现
    @Published var style: String
    // 角色 id
    @Published var role: String

    enum CodingKeys: String, CodingKey {
        case engine
        case rate
        case volume
        case style
        case role
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.engine = try container.decode(String.self, forKey: .engine)
        self.rate = try container.decode(Double.self, forKey: .rate)
        self.volume = try container.decode(Double.self, forKey: .volume)
        self.style = try container.decode(String.self, forKey: .style)
        self.role = try container.decode(String.self, forKey: .role)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(engine, forKey: .engine)
        try container.encode(rate, forKey: .rate)
        try container.encode(volume, forKey: .volume)
        try container.encode(style, forKey: .style)
        try container.encode(role, forKey: .role)
    }

    static func GetDefault() -> [String: Any] {
        return defaultRoleTTS
    }

    init(engine: String, rate: Double, volume: Double, style: String, role: String) {
        self.engine = engine
        self.rate = rate
        self.volume = volume
        self.style = style
        self.role = role
    }
}
