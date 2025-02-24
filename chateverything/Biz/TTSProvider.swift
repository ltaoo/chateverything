import Foundation
import AVFoundation
import Speech
import QCloudRealTTS
// TTS 引擎协议
public struct TTSCallback {
    let onStart: (() -> Void)?
    let onData: ((Data) -> Void)?
    let onComplete: (() -> Void)?
    let onCancel: (() -> Void)?
    let onError: ((Error) -> Void)?
    
    public init(
        onStart: @escaping () -> Void = {},
        onData: @escaping (Data) -> Void = { _ in },
        onComplete: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        self.onStart = onStart
        self.onData = onData
        self.onCancel = onCancel
        self.onError = onError
        self.onComplete = onComplete
    }
}

public protocol TTSEngine {
    func speak(_ text: String)
    func stop()
    func setConfig(config: [String: Any])
    func setEvents(callback: TTSCallback)
}

struct SystemTTSEngineConfig {
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var language: String = "en-US"
}
public class SystemTTSEngine: NSObject, TTSEngine, AVSpeechSynthesizerDelegate {
    private var synthesizer: AVSpeechSynthesizer
    private var callback: TTSCallback?
    var config: SystemTTSEngineConfig = SystemTTSEngineConfig()
    
    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
    }
    public func setConfig(config: [String: Any]) {
        if let v = config["speed"] as? Float {
            self.config.rate = v
        }
        if let v = config["pitch"] as? Float {
            self.config.pitch = v
        }
        if let v = config["volume"] as? Float {
            self.config.volume = v
        }
        if let v = config["language"] as? String {
            self.config.language = v
        }
    }
    public func setEvents(callback: TTSCallback) {
        self.callback = callback
    }
    public func speak(_ text: String) {
        self.callback?.onStart?()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: config.language)
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitch
        utterance.volume = config.volume
        synthesizer.speak(utterance)
    }
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        callback?.onCancel?()
        callback = nil
    }
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        callback?.onComplete?()
        callback = nil
    }
}

struct TencentTTSEngineConfig {
    var appId: String = ""
    var secretId: String = ""
    var secretKey: String = ""
    var token: String = ""
    var voiceType: Int = 1001
    var volume: Float = 1.0
    var speed: Float = 1.0
    var codec: String = "pcm"
}
struct TencentTTSEngineCredential {
    var appId: String = ""
    var secretId: String = ""
    var secretKey: String = ""
    var token: String = ""
}

// QCloud TTS 引擎
public class TencentTTSEngine: NSObject, TTSEngine {
//    private var language: String
    
    private var ttsConfig: QCloudRealTTSConfig?
    private var ttsController: QCloudRealTTSController?
    private var ttsListener: TencentTTSListener?
    private var callback: TTSCallback?
    var config: TencentTTSEngineConfig = TencentTTSEngineConfig()

    override init() {
        super.init()
    }
    
    public func setConfig(config: [String:Any]) {
        if let v = config["appId"] as? String {
            self.config.appId = v
        }
        if let v = config["secretId"] as? String {
            self.config.secretId = v
        }
        if let v = config["secretKey"] as? String {
            self.config.secretKey = v
        }
        if let v = config["token"] as? String {
            self.config.token = v
        }
        if let v = config["volume"] as? String,
           let volume = Float(v) {
            self.config.volume = volume
        }
        if let v = config["speed"] as? String,
           let speed = Float(v) {
            self.config.speed = speed
        }
        if let v = config["codec"] as? String {
            self.config.codec = v
        }
        if let v = config["role"] as? String,
           let voiceType = Int(v) {
            self.config.voiceType = voiceType
        }
    }

    public func setEvents(callback: TTSCallback) {
        self.callback = callback
    }
    
    public func speak(_ text: String) {
        self.callback?.onStart?()
        
        let builder = QCloudRealTTSConfig()
        builder.appID = config.appId
        builder.secretID = config.secretId
        builder.secretKey = config.secretKey
        builder.token = config.token
        // https://cloud.tencent.com/document/product/1073/92668
        builder.setApiParam("VoiceType", ivalue: config.voiceType) // 默认音色
        builder.setApiParam("Volume", fvalue: config.volume)
        builder.setApiParam("Speed", fvalue: config.speed)
        builder.setApiParam("Codec", value: config.codec)
        builder.setApiParam("Text", value: text)
        
        // 根据文本长度计算超时时间
        let baseTimeout = 5000 // 基础超时时间 5 秒
        let timePerChar = 100  // 每个字符额外增加 100 毫秒
        let timeout = baseTimeout + (text.count * timePerChar)
        let maxTimeout = 60000 // 最大超时时间 60 秒
        
        builder.connectTimeout = Int32(min(timeout, maxTimeout))
        
        ttsListener = TencentTTSListener(engine: self)
        ttsController = builder.build(ttsListener!)
        
    }
    
    public func stop() {
        ttsController?.cancel()
        callback?.onCancel?()
    }
    fileprivate func handleAudioData(_ data: Data) {
        callback?.onData?(data)
    }
    fileprivate func handleCompletion() {
        callback?.onComplete?()
    }
    fileprivate func handleError(_ error: Error) {
        callback?.onError?(error)
    }
    deinit {
        ttsController?.cancel()
        callback = nil
    }
}

// // QCloud TTS 监听器
public class TencentTTSListener: NSObject, QCloudRealTTSListener {
    private weak var engine: TencentTTSEngine?
    
    init(engine: TencentTTSEngine) {
        super.init()
        self.engine = engine
    }
    
    public func onFinish() {
        engine?.handleCompletion()
    }
    
    public func onError(_ error: Error) {
        engine?.handleError(error)
    }
    
    public func onData(_ data: Data) {
        engine?.handleAudioData(data)
    }
}

public class TTSCredential: ObservableObject {
    let appId: String?
    let secretId: String?
    let secretKey: String?

    init(appId: String?, secretId: String?, secretKey: String?) {
        self.appId = appId
        self.secretId = secretId
        self.secretKey = secretKey
    }
}

public class TTSProviderValue: ObservableObject {
	public var id: String
	@Published public var enabled: Bool
    @Published public var credential: [String:String]

    init(id: String, enabled: Bool, credential: [String:String]) {
        self.id = id
        self.enabled = enabled
        self.credential = credential
    }

    public func update(enabled: Bool) {
        self.enabled = enabled
    }
}

// 修改 TTSProvider 结构
public struct TTSProvider: Identifiable {
    public let id: String
    public let name: String
    public let logo_uri: String
    public let credential: FormObjectField?
    public let schema: FormObjectField
}

// 示例配置
public let TTSProviders = [
    TTSProvider(
        id: "system",
        name: "系统",
        logo_uri: "provider_light_system",
        credential: nil,
        schema: FormObjectField(
            id: "schema",
            key: "schema",
            label: "Schema",
            required: true,
            fields: [
                "language": .single(FormField(
                    id: "language",
                    key: "language",
                    label: "语言",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "language",
                        disabled: false,
                        defaultValue: "en-US",
                        options: [
                            FormSelectOption(id: "en-US", label: "英文", value: "en-US", description: "英文"),
                            FormSelectOption(id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                            FormSelectOption(id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                        ]
                    ))
                )),
                "volume": .single(FormField(
                    id: "volume",
                    key: "volume",
                    label: "音量",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "volume",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "speed": .single(FormField(
                    id: "speed",
                    key: "speed",
                    label: "语速",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "speed",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "pitch": .single(FormField(
                    id: "pitch",
                    key: "pitch",
                    label: "音调",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "pitch",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                ))
            ],
            orders: ["language", "volume", "speed", "pitch"]
        )
    ),
    // https://cloud.tencent.com/document/product/1073/37995
    TTSProvider(
        id: "tencent",
        name: "腾讯云",
        logo_uri: "provider_light_tencentcloud",
        credential: FormObjectField(
            id: "credential",
            key: "credential",
            label: "凭证",
            required: false,
            fields: [
                "appId": .single(FormField(
                    id: "appId",
                    key: "appId",
                    label: "AppID",
                    required: false,
                    input: .InputString(StringInput(
                        id: "appId",
                        defaultValue: nil
                    ))
                )),
                "secretId": .single(FormField(
                    id: "secretId",
                    key: "secretId",
                    label: "SecretID",
                    required: false,
                    input: .InputString(StringInput(
                        id: "secretId",
                        defaultValue: nil
                    ))
                )),
                "secretKey": .single(FormField(
                    id: "secretKey",
                    key: "secretKey",
                    label: "SecretKey",
                    required: false,
                    input: .InputString(StringInput(
                        id: "secretKey",
                        defaultValue: nil
                    ))
                )),
            ],
            orders: ["appId", "secretId", "secretKey"]
        ),
        schema: FormObjectField(
            id: "tts",
            key: "tts",
            label: "TTS",
            required: true,
            fields: [
                "voiceType": .single(FormField(
                    id: "voiceType",
                    key: "voiceType",
                    label: "角色",
                    required: true,
                    input: .InputSelect(SelectInput(
                        id: "voiceType",
                        defaultValue: "502001",
                        // https://cloud.tencent.com/document/product/1073/92668
                        options: [
                            FormSelectOption(id: "WeJames", label: "WeJames", value: "501008", description: "英文男声"),
                            FormSelectOption(id: "WeWinny", label: "WeWinny", value: "501009", description: "英文女声"),
                            FormSelectOption(id: "WeJack", label: "WeJack", value: "101050", description: "英文男声"),
                            FormSelectOption(id: "WeRose", label: "WeRose", value: "101051", description: "英文女声"),
                            FormSelectOption(id: "智小柔", label: "智小柔", value: "502001", description: "对话女声"),
                            FormSelectOption(id: "智斌", label: "智斌", value: "501000", description: "阅读男声"),
                            FormSelectOption(id: "智兰", label: "智兰", value: "501001", description: "资讯女声"),
                            FormSelectOption(id: "智菊", label: "智菊", value: "501002", description: "阅读女声"),
                            FormSelectOption(id: "智宇", label: "智宇", value: "501003", description: "阅读男声"),
                            FormSelectOption(id: "月华", label: "月华", value: "501004", description: "对话女声"),
                            FormSelectOption(id: "飞镜", label: "飞镜", value: "501005", description: "对话男声"),
                        ]
                    ))
                )),
                "language": .single(FormField(
                    id: "language",
                    key: "language",
                    label: "语言",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "language",
                        defaultValue: "en-US",
                        options: [
                            FormSelectOption(id: "en-US", label: "英文", value: "en-US", description: "英文"),
                            FormSelectOption(id: "zh-CN", label: "中文", value: "zh-CN", description: "中文"),
                            FormSelectOption(id: "jp-JP", label: "日文", value: "jp-JP", description: "日文"),
                        ]
                    ))
                )),
                "volume": .single(FormField(
                    id: "volume",
                    key: "volume",
                    label: "音量",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "volume",
                        defaultValue: 1.0,
                        min: -10.0,
                        max: 10.0
                    ))
                )),
                "speed": .single(FormField(
                    id: "speed",
                    key: "speed",
                    label: "语速",
                    required: false,
                    input: .InputSlider(SliderInput(
                        id: "speed",
                        defaultValue: 1.0,
                        min: 0.0,
                        max: 1.0,
                        step: 0.1
                    ))
                )),
                "codec": .single(FormField(
                    id: "codec",
                    key: "codec",
                    label: "编码",
                    required: false,
                    input: .InputSelect(SelectInput(
                        id: "codec",
                        defaultValue: "pcm",
                        options: [
                            FormSelectOption(id: "pcm", label: "pcm", value: "pcm", description: "pcm"),
                        ]
                    ))
                )),
                "stream": .single(FormField(
                    id: "stream",
                    key: "stream",
                    label: "流式",
                    required: false,
                    input: .InputBoolean(BooleanInput(
                        id: "stream",
                        defaultValue: false
                    ))
                ))
            ],
            orders: ["voiceType", "language", "volume", "speed", "codec", "stream"]
        )
    )
]




