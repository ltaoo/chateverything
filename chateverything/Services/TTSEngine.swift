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
        let language = "en-US"
        
        ttsConfig = QCloudRealTTSConfig()
        // 配置必要的参数
        ttsConfig?.appID = "1309267389" // 需要设置实际的 AppID
        ttsConfig?.secretID = "AKIDcDdqrtmTM9kXAbx7C5mGYgdQ1RfgU9j8" // 需要设置实际的 SecretID
        ttsConfig?.secretKey = "GNOEsJddS5WlndGiy2tzxnUT7zjHgttk" // 需要设置实际的 SecretKey
        ttsConfig?.token = "" // 需要设置实际的 Token
        ttsConfig?.connectTimeout = 20000 // 20秒超时
        
        // 设置基本参数
        // https://cloud.tencent.com/document/product/1073/92668
        ttsConfig?.setApiParam("VoiceType", ivalue: 601005) // 默认音色
        ttsConfig?.setApiParam("Volume", fvalue: 1.0)
        ttsConfig?.setApiParam("Speed", fvalue: 1.0)
        ttsConfig?.setApiParam("Codec", value: "pcm")
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

// 扩展 RealListener 以处理完成回调
// extension RealListener {
//     func setCompletionHandler(_ handler: @escaping () -> Void) {
//         // 在 onFinish 中调用 handler
//     }
// }

// TTS 引擎管理器
class TTSManager {
    static let shared = TTSManager()
    
    enum EngineType {
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
