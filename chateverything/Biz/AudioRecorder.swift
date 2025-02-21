import Foundation
import AVFoundation

// 录音管理类
class AudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var onError: ((Error) -> Void)?
    var onBegin: (() -> Void)?
    var onCompleted: ((URL) -> Void)?
    var onCancel: (() -> Void)?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var tmpCompleted: (() -> Void)?
    private var playbackCompleted: (() -> Void)?

    @Published var isRecording = false
    @Published var isPlaying = false
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }
    
    func startRecording() {
        onBegin?()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording.m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            self.isRecording = true
            audioRecorder?.record()
        } catch {
            onError?(error)
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        audioRecorder?.stop()
        self.isRecording = false
        // 生成唯一的文件名
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).m4a"
        let permanentURL = documentsPath.appendingPathComponent(fileName)
        
        // 将临时录音文件移动到永久位置
        if let originalURL = recordingURL {
            try? FileManager.default.moveItem(at: originalURL, to: permanentURL)
            completion(permanentURL)
            onCompleted?(permanentURL)
            return
        }
        onError?(NSError(domain: "AudioRecorderError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to move recording to permanent location"]))
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        self.isRecording = false
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        onCancel?()
    }
    
    func playAudio(url: URL, onComplete: @escaping () -> Void) {
        do {
            // 设置音频会话
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            
            // 创建并配置音频播放器
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            self.isPlaying = true
            self.tmpCompleted = onComplete
            self.playbackCompleted = handlePlayingCompleted
        } catch {
            print("Failed to play audio: \(error)")
            onError?(error)
        }
    }

    func handlePlayingCompleted() {
        self.isPlaying = false
        self.tmpCompleted?()
        self.tmpCompleted = nil
    }
    
    // AVAudioPlayerDelegate 方法
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.tmpCompleted?()
            self?.tmpCompleted = nil
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        self.tmpCompleted?()
        self.tmpCompleted = nil
    }
    
    func cleanup() {
        // 停止录音
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        self.isRecording = false
        
        // 停止播放
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.isPlaying = false
        self.tmpCompleted?()
        self.tmpCompleted = nil
        self.playbackCompleted = nil

        self.recordingURL = nil
        
        // 清理音频会话
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
            onError?(error)
        }
        #endif
    }
}
