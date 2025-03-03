import SwiftUI
import Foundation
import AVFoundation
import Speech


struct StreamVoiceInputExample: View {
    var sessionId: UUID
    var store: ChatStore
    var config: Config
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: ChatDetailViewModel
    @StateObject private var recorder: AudioRecorder

    @State private var toastMessage: String?
    @State private var currentRecognizedText: String = ""
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    init(sessionId: UUID, config: Config) {
        self.sessionId = sessionId
        self.config = config
        self.store = config.store
        _model = StateObject(wrappedValue: ChatDetailViewModel(id: sessionId, config: config, store: config.store))
        _recorder = StateObject(wrappedValue: AudioRecorder())
    }

    // 将回调设置移到 onAppear
    private func setupRecorderCallbacks() {
        // 开始录音时设置实时识别
        self.recorder.onBegin = {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // 检查语音识别权限
                        SFSpeechRecognizer.requestAuthorization { status in
                            DispatchQueue.main.async {
                                switch status {
                                case .authorized:
                                    self.setupLiveRecognition() // 开始实时识别
                                case .denied, .restricted, .notDetermined:
                                    self.model.showPermissionAlert()
                                @unknown default:
                                    print("Unknown speech recognition authorization status")
                                }
                            }
                        }
                    } else {
                        self.model.showPermissionAlert()
                    }
                }
            }
        }
        
        // 录音完成时停止识别
        self.recorder.onCompleted = { url in
            print("complete audio recording, the url: \(url)")
            // 停止实时识别
            self.stopLiveRecognition()
            // 保存录音文件
            self.handleRecognizedSpeech(recognizedText: self.currentRecognizedText, audioURL: url, duration: 0)
        }
    }

    func handleBeginRecording() {
    }
    
    private func playAudioMessage(url: URL) {
        // if self.isPlaying {
        //     audioRecorder.stopPlayback()
        //     self.isPlaying = false
        // } else {
        //     audioRecorder.playAudio(url: url) {
        //         self.isPlaying = false
        //     }
        //     self.isPlaying = true
        // }
    }
    
    private func toggleSpeaking(message: ChatBoxBiz) {
        // if message.isSpeaking {
        //     TTSManager.shared.stopSpeaking()
        //     message.isSpeaking = false
        // } else {
        //     TTSManager.shared.speak(message.data.text) {
        //         DispatchQueue.main.async {
        //             message.isSpeaking = false
        //         }
        //     }
        //     message.isSpeaking = true
        // }
    }
    
    private func recognizeSpeech(url: URL) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            DispatchQueue.main.async {
                self.model.showPermissionAlert()
            }
            return
        }
        
        SFSpeechRecognizer.requestAuthorization {  status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.performSpeechRecognition(recognizer: recognizer, url: url)
                case .denied, .restricted, .notDetermined:
                    self.model.showPermissionAlert()
                @unknown default:
                    self.toastMessage = "未知的语音识别授权状态"
                    print("Unknown speech recognition authorization status")
                }
            }
        }
    }
    
    private func performSpeechRecognition(recognizer: SFSpeechRecognizer, url: URL) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        // 启用实时识别结果
        request.shouldReportPartialResults = true
        
        // 设置任务选项为听写模式
        request.taskHint = .dictation
        
        // 获取音频时长
        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        let duration = audioPlayer?.duration ?? 0
        
        // 创建一个变量存储最终识别文本
        var finalText = ""
        
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Recognition failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else { return }
            
            // 获取当前识别文本
            let recognizedText = result.bestTranscription.formattedString
            print("Current recognition: \(recognizedText)")
            
            // 如果是最终结果
            if result.isFinal {
                finalText = recognizedText
                self.handleRecognizedSpeech(recognizedText: finalText, audioURL: url, duration: duration)
            }
        }
    }
    
    private func setupLiveRecognition() {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechAudioBufferRecognitionRequest()
        
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        
        guard let recognizer = recognizer else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    print("Live recognition: \(recognizedText)")
                    self.currentRecognizedText = recognizedText
                }
                
                if error != nil {
                    self.stopLiveRecognition()
                }
            }
        } catch {
            print("Error setting up live recognition: \(error)")
        }
    }
    
    private func stopLiveRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
//        audioEngine = nil
//        recognitionTask = nil
    }
    
    private func handleRecognizedSpeech(recognizedText: String, audioURL: URL, duration: TimeInterval) {
        if recognizedText.isEmpty {
            print("recognizedText is empty")
            return
        }
        print("handleRecognizedSpeech \(recognizedText)")
        let viewModel = self.model
        let userMessage = ChatBoxBiz(
            id: UUID(),
            type: "audio",
            created_at: Date(),
            isMe: true,
            payload_id: UUID(),
            session_id: viewModel.session.id,
            sender_id: config.me.id,
            payload: ChatPayload.audio(
                ChatAudioBiz(
                    text: recognizedText,
                    nodes: [],
                    url: audioURL,
                    duration: duration
                )
            ),
            loading: false
        )
        viewModel.session.appendBox(box: userMessage)

        // for member in viewModel.session.members {
        //     if let role = member.role {
        //         let box = role.response(text: recognizedText, session: viewModel.session, config: config)
        //         viewModel.session.append(box: box) { boxes in
        //             print("Current box count: \(boxes.count)")
        //             viewModel.boxes = boxes
        //         }
        //     }
        // }
    }
    
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Int(-startTime.timeIntervalSinceNow)
        return String(format: "%d:%02d", duration / 60, duration % 60)
    }

    func onMounted() {
        
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("hello")
        }
        .navigationBarTitleDisplayMode(.inline)
        // 添加导航栏底部分隔线
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(uiColor: .systemGray4))
            .offset(y: -1)
        , alignment: .top
        )
        // 添加导航栏背景色
        .sheet(isPresented: $model.roleDetailVisible) {
            // let session = self.model.session
            // RoleDetailView(session: session)
        }
        .onAppear {
            setupRecorderCallbacks()
            model.load()
        }
        .onDisappear {
            self.recorder.cleanup()
        }
    }
}
