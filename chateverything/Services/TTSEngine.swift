import Foundation
import AVFoundation
import QCloudRealTTS
import Speech

// TTS 引擎协议
protocol TTSEngine {
    func speak(_ text: String, completion: @escaping () -> Void)
    func stopSpeaking()
}

// 系统内置 TTS 引擎
class SystemTTSEngine: NSObject, TTSEngine, AVSpeechSynthesizerDelegate {
//    private var language: String
    private let synthesizer: AVSpeechSynthesizer
    private var completionHandler: (() -> Void)?
    
    override init() {
        synthesizer = AVSpeechSynthesizer()
        
        super.init()
//        language = lang
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        let language = "en-US"
        completionHandler = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler?()
        completionHandler = nil
    }
    
    // AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completionHandler?()
        completionHandler = nil
    }
}


class PCMStreamPlayer {
    var engine: AVAudioEngine
    private var in_format: AVAudioFormat
    private var out_format: AVAudioFormat
    var player_node: AVAudioPlayerNode
    private var converter: AVAudioConverter
    private var tail = Data()
    
    init() {
        do {
            // 修改音频会话配置，支持播放和录音
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, 
                                      mode: .default,
                                      options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            self.engine = AVAudioEngine()
            player_node = AVAudioPlayerNode()
            in_format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
            out_format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            converter = AVAudioConverter(from: in_format, to: out_format)!
            engine.attach(player_node)
            engine.connect(player_node, to: engine.outputNode, format: out_format)
            try engine.start()
            player_node.play()
        } catch {
            print("PCMStreamPlayer initialization error: \(error)")
            exit(-1)
        }
    }
    
    func put(data: Data) {
        print("[PCMStreamPlayer] Received data chunk: \(data.count) bytes")
        // 忽略空数据
        if data.count == 0 {
            print("[PCMStreamPlayer] Ignoring empty data chunk")
            return
        }
        
        var local_data = data
        tail.append(local_data)
        local_data = tail
        
        // 确保引擎和节点处于活动状态
        if !engine.isRunning {
            do {
                try engine.start()
                player_node.play()
                print("[PCMStreamPlayer] Restarted audio engine")
            } catch {
                print("[PCMStreamPlayer] Failed to restart audio engine: \(error)")
            }
        }
        
        if (tail.count % 2 == 1) {
            tail = local_data.subdata(in: tail.count-1..<tail.count)
            local_data.count = local_data.count - 1
        } else {
            tail = Data()
        }
        if (local_data.count == 0) {
            print("[PCMStreamPlayer] Warning: Empty data chunk")
            return
        }
        let in_buffer = AVAudioPCMBuffer(pcmFormat: in_format, frameCapacity: AVAudioFrameCount(local_data.count) / in_format.streamDescription.pointee.mBytesPerFrame)!
        in_buffer.frameLength = in_buffer.frameCapacity
        if let channels = in_buffer.int16ChannelData {
            let int16arr = local_data.withUnsafeBytes {
                Array(UnsafeBufferPointer<Int16>(start: $0.baseAddress!.assumingMemoryBound(to: Int16.self), count: local_data.count / MemoryLayout<Int16>.size))
            }
            for i in 0..<Int(in_buffer.frameLength) {
                channels[0][i] = int16arr[i]
            }
        }
        let out_buffer = AVAudioPCMBuffer(pcmFormat: out_format, frameCapacity: in_buffer.frameCapacity)!
        do {
            try converter.convert(to: out_buffer, from: in_buffer)
            print("[PCMStreamPlayer] Successfully converted and scheduled buffer")
        } catch {
            print("[PCMStreamPlayer] Conversion error: \(error)")
            exit(-1)
        }
        player_node.scheduleBuffer(out_buffer)
    }
    
    deinit {
        print("[PCMStreamPlayer] Cleaning up resources")
        player_node.stop()
        engine.stop()
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

    override init() {
        super.init()
        player = PCMStreamPlayer()
        setupEngine()
    }
    
    private func setupEngine() {
        ttsConfig = QCloudRealTTSConfig()
        // 配置必要的参数
        ttsConfig?.appID = "1309267389"
        ttsConfig?.secretID = "AKIDcDdqrtmTM9kXAbx7C5mGYgdQ1RfgU9j8"
        ttsConfig?.secretKey = "GNOEsJddS5WlndGiy2tzxnUT7zjHgttk"
        ttsConfig?.token = ""
        ttsConfig?.connectTimeout = 20000
        
        // 设置基本参数
        ttsConfig?.setApiParam("Volume", fvalue: 1.0)
        ttsConfig?.setApiParam("Speed", fvalue: 1.0)
        ttsConfig?.setApiParam("Codec", value: "pcm")
        
        // 默认使用 WeJames 音色
        ttsConfig?.setApiParam("VoiceType", ivalue: 501008)
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
    
    func stopSpeaking() {
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
            try AVAudioSession.sharedInstance().setActive(false, 
                                                        options: .notifyOthersOnDeactivation)
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

struct TTSEngineRole: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let voice: String    // 音色ID
    let language: String
    let description: String // 音色描述

    static func == (lhs: TTSEngineRole, rhs: TTSEngineRole) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct TTSEngineOption: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let roles: [TTSEngineRole]
    
    static func == (lhs: TTSEngineOption, rhs: TTSEngineOption) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

let TTSEngineOptions = [
    TTSEngineOption(name: "系统", roles: [
        TTSEngineRole(name: "默认", voice: "默认", language: "en-US", description: "系统默认语音"),
    ]),
    TTSEngineOption(name: "腾讯云", roles: [
      
    ]),
]

// 扩展 RealListener 以处理完成回调
// extension RealListener {
//     func setCompletionHandler(_ handler: @escaping () -> Void) {
//         // 在 onFinish 中调用 handler
//     }
// }

// TTS 引擎管理器
class TTSManager {
    static let shared = TTSManager()
    
    enum EngineType: String, CaseIterable {
        case system
        case qcloud
        // 可以继续添加其他引擎类型
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
    
    func stopSpeaking() {
        currentEngine.stopSpeaking()
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

struct TTSCredential: Identifiable {
    let appId: String?
    let secretId: String?
    let secretKey: String?
}

// 修改 TTSProvider 结构
struct TTSProvider: Identifiable {
    let id: String
    let name: String
    let logo_uri: String
    let stream: Bool
    let credential: TTSCredential
    let roles: [TTSEngineRole]
}

// 示例配置
let TTSProviders = [
    TTSProvider(
        id: "system",
        name: "系统",
        logo_uri: "https://qcloud.com/logo.png",
        stream: false,
        credential: TTSCredential(
            appId: nil,
            secretId: nil,
            secretKey: nil
        ),
        roles: [],
        configFields: [
            TTSConfigField(
                id: "system_gender",
                key: "gender",
                label: "声音性别",
                type: .singleSelect,
                defaultValue: "female",
                description: "选择声音性别",
                options: [
                    TTSConfigOption(id: "male", label: "男声", value: "male", description: nil),
                    TTSConfigOption(id: "female", label: "女声", value: "female", description: nil)
                ],
                min: nil,
                max: nil,
                step: nil,
                required: true,
                placeholder: nil
            )
        ]
    ),
    TTSProvider(
        id: "qcloud",
        name: "腾讯云",
        logo_uri: "https://qcloud.com/logo.png",
        credential: TTSCredential(
            appId: nil,
            secretId: nil,
            secretKey: nil
        ),
        roles: [
            TTSEngineRole(name: "WeJames", voice: "501008", language: "en-US", description: "英文男声"),
            TTSEngineRole(name: "WeWinny", voice: "501009", language: "en-US", description: "英文女声"),
            TTSEngineRole(name: "WeJack", voice: "101050", language: "en-US", description: "英文男声"),
            TTSEngineRole(name: "WeRose", voice: "101051", language: "en-US", description: "英文女声"),
            TTSEngineRole(name: "智小柔", voice: "502001", language: "zh-CN", description: "对话女声"),
            TTSEngineRole(name: "智斌", voice: "501000", language: "zh-CN", description: "阅读男声"),
            TTSEngineRole(name: "智兰", voice: "501001", language: "zh-CN", description: "资讯女声"),
            TTSEngineRole(name: "智菊", voice: "501002", language: "zh-CN", description: "阅读女声"),
            TTSEngineRole(name: "智宇", voice: "501003", language: "zh-CN", description: "阅读男声"),
            TTSEngineRole(name: "月华", voice: "501004", language: "zh-CN", description: "对话女声"),
            TTSEngineRole(name: "飞镜", voice: "501005", language: "zh-CN", description: "对话男声"),
        ],
        configFields: [
            TTSConfigField(
                id: "qcloud_speed",
                key: "speed",
                label: "语速",
                type: .slider,
                defaultValue: 1.0,
                description: "调节语音速度",
                options: nil,
                min: 0.5,
                max: 2.0,
                step: 0.1,
                required: true,
                placeholder: nil
            ),
            TTSConfigField(
                id: "qcloud_volume",
                key: "volume",
                label: "音量",
                type: .slider,
                defaultValue: 1.0,
                description: "调节语音音量",
                options: nil,
                min: 0.0,
                max: 1.0,
                step: 0.1,
                required: true,
                placeholder: nil
            ),
            TTSConfigField(
                id: "qcloud_role",
                key: "role",
                label: "语音角色",
                type: .singleSelect,
                defaultValue: "501008",
                description: "选择语音角色",
                options: [
                    TTSConfigOption(id: "501008", label: "WeJames", value: "501008", description: "英文男声"),
                    TTSConfigOption(id: "501009", label: "WeWinny", value: "501009", description: "英文女声")
                    // ... 可以添加更多角色选项
                ],
                min: nil,
                max: nil,
                step: nil,
                required: true,
                placeholder: nil
            )
        ]
    ),
]


