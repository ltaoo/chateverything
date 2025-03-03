import AVFoundation
import Foundation
import QCloudRealTTS

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
    func clear()
    func setConfig(config: [String: Any])
    func setEvents(callback: TTSCallback)
}

struct SystemTTSEngineConfig {
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var viceType: String = "female"
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
        if let v = config["viceType"] as? String {
            self.config.viceType = v
        }
    }
    public func setEvents(callback: TTSCallback) {
        self.callback = callback
    }
    public func speak(_ text: String) {
        self.callback?.onStart?()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: config.language)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let desiredVoices = voices.filter { voice in
            voice.identifier == config.viceType
        }
        utterance.voice = desiredVoices.first ?? AVSpeechSynthesisVoice(language: config.language)
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitch
        utterance.volume = config.volume
        synthesizer.speak(utterance)
    }
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        callback?.onCancel?()
    }
    public func clear() {
    }
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        print("[TTS]SystemTTSEngine didFinish")
        callback?.onComplete?()
    }

    deinit {
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

    private var builder = QCloudRealTTSConfig()
    private var ttsConfig: QCloudRealTTSConfig?
    private var ttsController: QCloudRealTTSController?
    private var ttsListener: TencentTTSListener?
    private var callback: TTSCallback?
    var config: TencentTTSEngineConfig = TencentTTSEngineConfig()
    var player: PCMStreamPlayer?
    var state: Int = 0
    var msg: String = ""

    override init() {
        super.init()
    }

    public func setConfig(config: [String: Any]) {
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
            let volume = Float(v)
        {
            self.config.volume = volume
        }
        if let v = config["speed"] as? String,
            let speed = Float(v)
        {
            self.config.speed = speed
        }
        if let v = config["codec"] as? String {
            self.config.codec = v
        }
        if let v = config["voiceType"] as? String,
            let voiceType = Int(v)
        {
            self.config.voiceType = voiceType
        }
    }

    public func setEvents(callback: TTSCallback) {
        self.callback = callback
    }

    public func speak(_ text: String) {
        self.callback?.onStart?()
        state = 1

        if self.player != nil {
            self.player = nil
        }
        self.player = PCMStreamPlayer()

        self.builder = QCloudRealTTSConfig()
        self.builder.appID = self.config.appId
        self.builder.secretID = self.config.secretId
        self.builder.secretKey = self.config.secretKey
        self.builder.token = self.config.token
        print(
            "[TTS]TencentTTSEngine credential: \(self.config.appId) \(self.config.secretId) \(self.config.secretKey) \(self.config.token)"
        )
        print(
            "[TTS]TencentTTSEngine config: \(self.config.voiceType) \(self.config.volume) \(self.config.speed) \(self.config.codec)"
        )
        // https://cloud.tencent.com/document/product/1073/92668
        self.builder.setApiParam("VoiceType", ivalue: self.config.voiceType)
        self.builder.setApiParam("Volume", fvalue: self.config.volume)
        self.builder.setApiParam("Speed", fvalue: self.config.speed)
        self.builder.setApiParam("Codec", value: self.config.codec)
        self.builder.setApiParam("Text", value: text)

        // 根据文本长度计算超时时间
        let baseTimeout = 5000  // 基础超时时间 5 秒
        let timePerChar = 100  // 每个字符额外增加 100 毫秒
        let timeout = baseTimeout + (text.count * timePerChar)
        let maxTimeout = 60000  // 最大超时时间 60 秒

        self.builder.connectTimeout = Int32(min(timeout, maxTimeout))

        self.ttsListener = TencentTTSListener(engine: self)
        self.ttsController = self.builder.build(self.ttsListener!)
        self.state = 2
    }
    public func clear() {
        print("[TTS]TencentTTSEngine clear")
        player = nil
    }
    public func stop() {
        ttsController?.cancel()
        callback?.onCancel?()
        state = 5
    }
    fileprivate func handleAudioData(_ data: Data) {
        player?.put(data: data)
        state = 3
        callback?.onData?(data)
    }
    fileprivate func handleCompletion() {
        state = 4
        callback?.onComplete?()
    }
    fileprivate func handleError(_ error: Error) {
        callback?.onError?(error)
        print("[TTS]TencentTTSEngine handleError: \(error)")
        state = 6
        player = nil
    }
    deinit {
        ttsController?.cancel()
        callback = nil
        player = nil
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
