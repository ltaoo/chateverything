import Foundation
import AVFoundation
import Speech
import QCloudRealTTS

// TTS 引擎协议
protocol TTSEngine {
    func speak(_ text: String, completion: @escaping () -> Void)
    func stop()
}

// 系统内置 TTS 引擎
class SystemTTSEngine: NSObject, TTSEngine, AVSpeechSynthesizerDelegate {
    private let synthesizer: AVSpeechSynthesizer
    private var completionHandler: (() -> Void)?
    var config: [String: String] = [:]
    
    override init() {
        synthesizer = AVSpeechSynthesizer()
        
        super.init()
//        language = lang
        synthesizer.delegate = self
    }
    func setConfig(config: [String: String]) {
        self.config = config
    }
    func speak(_ text: String, completion: @escaping () -> Void) {
        let language = config["language"] ?? "en-US"
        completionHandler = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        if let rate = Float(config["speed"] ?? "0.5") {
            utterance.rate = rate
        }
        utterance.pitchMultiplier = 1.0
        if let pitchMultiplier = Float(config["pitch"] ?? "1.0") {
            utterance.pitchMultiplier = pitchMultiplier
        }
        utterance.volume = 1.0
        if let volume = Float(config["volume"] ?? "1.0") {
            utterance.volume = volume
        }

        synthesizer.speak(utterance)
    }
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler?()
        completionHandler = nil
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completionHandler?()
        completionHandler = nil
    }
}


// QCloud TTS 引擎
class QCloudTTSEngine: NSObject, TTSEngine {
//    private var language: String
    
    private var ttsConfig: QCloudRealTTSConfig?
    private var ttsController: QCloudRealTTSController?
    private var ttsListener: QCloudTTSListener?
    private var completionHandler: (() -> Void)?
    private var player: PCMStreamPlayer?
    var credential: [String: String] = [:]
    var config: [String: String] = [:]

    override init() {
        super.init()
        player = PCMStreamPlayer()
        setupEngine()
    }
    
    private func setupEngine() {
        let config = QCloudRealTTSConfig()
        // 配置必要的参数
        config.appID = credential["appId"] ?? ""
        config.secretID = credential["secretId"] ?? ""
        config.secretKey = credential["secretKey"] ?? ""
        config.token = ""
        config.connectTimeout = 20000
        // 设置基本参数
        if let volume = Float(self.config["volume"] ?? "1.0") {
            config.setApiParam("Volume", fvalue: volume)
        }
        if let speed = Float(self.config["speed"] ?? "1.0") {
            config.setApiParam("Speed", fvalue: speed)
        }
        if let codec = self.config["codec"] {
            config.setApiParam("Codec", value: codec)
        }
        if let role = Int(self.config["role"] ?? "501008") {
            config.setApiParam("VoiceType", ivalue: role)
        }
        self.ttsConfig = config
    }
    
    func setVoice(_ voiceId: String) {
        if let voiceIdInt = Int(voiceId) {
            ttsConfig?.setApiParam("VoiceType", ivalue: voiceIdInt)
        }
    }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        print("[TTSEngine]QCloudTTSEngine speak: \(text)")
        completionHandler = completion
        
        // 重新初始化 player
        player = PCMStreamPlayer()
        
        // 根据文本长度计算超时时间
        let baseTimeout = 5000 // 基础超时时间 5 秒
        let timePerChar = 100  // 每个字符额外增加 100 毫秒
        let timeout = baseTimeout + (text.count * timePerChar)
        let maxTimeout = 60000 // 最大超时时间 60 秒
        
        ttsConfig?.connectTimeout = Int32(min(timeout, maxTimeout))
        ttsConfig?.setApiParam("Text", value: text)
        
        // 创建新的监听器
        ttsListener = QCloudTTSListener(engine: self)
        
        // 构建控制器
        if let config = ttsConfig, let listener = ttsListener {
            ttsController = config.build(listener)
        }
    }
    
    func stop() {
        print("[TTSEngine] Stopping speech")
        ttsController?.cancel()
        // 先停止播放器
        if let player = player {
            player.player_node.stop()
            player.engine.stop()
        }
        player = nil
        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(
                false, 
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("[TTSEngine] Failed to deactivate audio session: \(error)")
        }
        completionHandler?()
        completionHandler = nil
    }
    fileprivate func handleAudioData(_ data: Data) {
        print("[TTSEngine] Received audio data chunk: \(data.count) bytes")
        player?.put(data: data)
    }
    fileprivate func handleCompletion() {
        print("[TTSEngine] TTS synthesis completed")
        // 延长等待时间，确保音频完全播放
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // 先停止播放器
            if let player = self.player {
                player.player_node.stop()
                player.engine.stop()
            }
            
            print("[TTSEngine] Attempting to reset audio session")
            do {
                // 先设置为非活动
                try AVAudioSession.sharedInstance().setActive(false, 
                                                            options: .notifyOthersOnDeactivation)
                // 短暂延迟后重新激活
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        print("[TTSEngine] Successfully reset audio session")
                    } catch {
                        print("[TTSEngine] Failed to reactivate audio session: \(error)")
                    }
                }
            } catch {
                print("[TTSEngine] Failed to deactivate audio session: \(error)")
            }
            
            self.completionHandler?()
            self.completionHandler = nil
            self.player = nil
        }
    }
    fileprivate func handleError(_ error: Error) {
        print("[TTSEngine] Error occurred: \(error.localizedDescription)")
        completionHandler?()
        completionHandler = nil
    }
    deinit {
        ttsController?.cancel()
    }
}

// QCloud TTS 监听器
private class QCloudTTSListener: NSObject, QCloudRealTTSListener {
    private weak var engine: QCloudTTSEngine?
    
    init(engine: QCloudTTSEngine) {
        super.init()

        self.engine = engine
    }
    
    func onFinish() {
        engine?.handleCompletion()
    }
    
    func onError(_ error: Error) {
        engine?.handleError(error)
    }
    
    func onData(_ data: Data) {
        engine?.handleAudioData(data)
    }
}

// TTS 引擎管理器
class TTSManager {
    static let shared = TTSManager()
    
    enum EngineType: String, CaseIterable {
        case system
        case qcloud
    }
    
    private var currentEngine: TTSEngine
    
    private init() {
        // 默认使用系统引擎
        // currentEngine = SystemTTSEngine()
        currentEngine = QCloudTTSEngine()
    }
    
    func switchEngine(_ type: EngineType) {
        switch type {
        case .system:
            currentEngine = SystemTTSEngine()
        case .qcloud:
            currentEngine = QCloudTTSEngine()
        }
    }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        currentEngine.speak(text, completion: completion)
    }
    
    func stop() {
        currentEngine.stop()
    }
    
    func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // 麦克风权限请求
            DispatchQueue.main.async {
                if !granted {
                    completion(false)
                }
            }
        }
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
                        max: 1.0
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
                        max: 1.0
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
                        max: 1.0
                    ))
                ))
            ]
        )
    ),
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
            ]
        ),
        schema: FormObjectField(
            id: "tts",
            key: "tts",
            label: "TTS",
            required: true,
            fields: [
                "role": .single(FormField(
                    id: "role",
                    key: "role",
                    label: "角色",
                    required: true,
                    input: .InputSelect(SelectInput(
                        id: "role",
                        defaultValue: "502001",
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
                        max: 1.0
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
                        max: 1.0
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
            ]
        )
    )
]




