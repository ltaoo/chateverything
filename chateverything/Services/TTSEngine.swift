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
    private let synthesizer: AVSpeechSynthesizer
    private var completionHandler: (() -> Void)?
    
    override init() {
        synthesizer = AVSpeechSynthesizer()
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        completionHandler = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
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
    private var engine: AVAudioEngine
    private var in_format: AVAudioFormat
    private var out_format: AVAudioFormat
    private var player_node: AVAudioPlayerNode
    private var converter: AVAudioConverter
    private var tail = Data()
    
    init() {
        do {
            try AVAudioSession().setCategory(.playback)
            self.engine = AVAudioEngine()
            player_node = AVAudioPlayerNode()
            in_format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
            out_format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            converter = AVAudioConverter(from: in_format, to: out_format)!
            engine.attach(player_node)
            engine.connect(player_node, to: engine.outputNode, format: out_format)
            try engine.start()
            player_node.play()
        }catch {
            exit(-1)
        }
    }
    
    func put(data: Data) {
        var local_data = data
        tail.append(local_data)
        local_data = tail
        if (tail.count % 2 == 1) {
            tail = local_data.subdata(in: tail.count-1..<tail.count)
            local_data.count = local_data.count - 1
        } else {
            tail = Data()
        }
        if (local_data.count == 0) {
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
        do{
            try converter.convert(to: out_buffer, from: in_buffer)
        }catch {
            exit(-1)
        }
        player_node.scheduleBuffer(out_buffer)
    }
    
}

// QCloud TTS 引擎
class QCloudTTSEngine: NSObject, TTSEngine {
    private var ttsConfig: QCloudRealTTSConfig?
    private var ttsController: QCloudRealTTSController?
    private var ttsListener: QCloudTTSListener?
    private var completionHandler: (() -> Void)?
    private var player: PCMStreamPlayer?

    override init() {
        player = PCMStreamPlayer()
        super.init()
        setupEngine()
    }
    
    private func setupEngine() {
        ttsConfig = QCloudRealTTSConfig()
        // 配置必要的参数
        ttsConfig?.appID = "1309267389" // 需要设置实际的 AppID
        ttsConfig?.secretID = "AKIDcDdqrtmTM9kXAbx7C5mGYgdQ1RfgU9j8" // 需要设置实际的 SecretID
        ttsConfig?.secretKey = "GNOEsJddS5WlndGiy2tzxnUT7zjHgttk" // 需要设置实际的 SecretKey
        ttsConfig?.token = "" // 需要设置实际的 Token
        ttsConfig?.connectTimeout = 5000 // 5秒超时
        
        // 设置基本参数
        // https://cloud.tencent.com/document/product/1073/92668
        ttsConfig?.setApiParam("VoiceType", ivalue: 601005) // 默认音色
        ttsConfig?.setApiParam("Volume", fvalue: 1.0)
        ttsConfig?.setApiParam("Speed", fvalue: 1.0)
        ttsConfig?.setApiParam("Codec", value: "pcm")
    }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        completionHandler = completion
        
        ttsConfig?.setApiParam("Text", value: text)
        
        // 创建新的监听器
        ttsListener = QCloudTTSListener(engine: self)
        
        // 构建控制器
        if let config = ttsConfig, let listener = ttsListener {
            ttsController = config.build(listener)
        }
    }
    
    func stopSpeaking() {
        ttsController?.cancel()
        completionHandler?()
        completionHandler = nil
    }
    
    fileprivate func handleAudioData(_ data: Data) {
        player?.put(data: data)
    }
    
    fileprivate func handleCompletion() {
        completionHandler?()
        completionHandler = nil
    }
    
    fileprivate func handleError(_ error: Error) {
        print("TTS Error: \(error.localizedDescription)")
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
        self.engine = engine
        super.init()
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