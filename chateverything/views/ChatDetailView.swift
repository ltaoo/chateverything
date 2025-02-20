import SwiftUI
import AVFoundation
import Speech
import LLM

// 聊天详情页面
struct ChatDetailView: View {
    @EnvironmentObject private var navigationManager: NavigationStateManager
    let chatSession: ChatSession
    let model: LLMService
    @State private var isPlaying = false
    
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
    ]
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var scale: CGFloat = 1.0
    @State private var isLoading = false
    @State private var cancelHighlighted = false
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingPermissionAlert = false
    @State private var isSpeaking = false
    @State private var showPromptPopover = false
    
    let roleId: UUID  // 添加参数
    
    init(chatSession: ChatSession, model: LLMService, roleId: UUID) {
        self.chatSession = chatSession
        self.model = model
        self.roleId = roleId
    }
    
    private func startRecording() {
        if isSpeaking {
            TTSManager.shared.stopSpeaking()
            isSpeaking = false
        }
        
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if granted {
                    self.beginRecording()
                } else {
                    self.showingPermissionAlert = true
                }
            }
        }
        #else
        beginRecording()
        #endif
    }
    
    private func beginRecording() {
        isRecording = true
        recordingStartTime = Date()
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
            scale = 1.2
        }
        audioRecorder.startRecording()
        
        // 使用 Timer 更新录音时间
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if !self.isRecording {
                timer.invalidate()
            } else {
                self.recordingStartTime = Date(timeInterval: 0, since: self.recordingStartTime ?? Date())
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recordingStartTime = nil
        scale = 1.0
        
        // 停止录音并进行语音识别
        audioRecorder.stopRecording { url in
            print("complete audio recoding, the url: \(String(describing: url))")
            if let url = url {
                recognizeSpeech(url: url)
            }
        }
    }
    
    private func cancelRecording() {
        isRecording = false
        recordingStartTime = nil
        scale = 1.0
        audioRecorder.cancelRecording()
    }
    
    private func toggleSpeaking(text: String) {
        if isSpeaking {
            TTSManager.shared.stopSpeaking()
            isSpeaking = false
        } else {
            TTSManager.shared.speak(text, completion: {
                DispatchQueue.main.async { [self] in
                    isSpeaking = false
                }
            })
            isSpeaking = true
        }
    }
    
    private func recognizeSpeech(url: URL) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            DispatchQueue.main.async {
                self.showingPermissionAlert = true
            }
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.performSpeechRecognition(recognizer: recognizer, url: url)
                case .denied, .restricted, .notDetermined:
                    self.showingPermissionAlert = true
                @unknown default:
                    print("Unknown speech recognition authorization status")
                }
            }
        }
    }
    
    private func performSpeechRecognition(recognizer: SFSpeechRecognizer, url: URL) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Recognition failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, result.isFinal else { return }
            
            let recognizedText = result.bestTranscription.formattedString
            self.handleRecognizedSpeech(recognizedText: recognizedText, audioURL: url)
        }
    }
    
    private func handleRecognizedSpeech(recognizedText: String, audioURL: URL) {
        DispatchQueue.main.async {
            let userMessage = ChatMessage(
                content: recognizedText,
                isMe: true,
                timestamp: Date(),
                nodes: nil,
                audioURL: audioURL
            )
            self.messages.append(userMessage)
            
            Task {
                do {
                    let response = try await self.model.chat(content: recognizedText)
                    
                    let quizOptions = [
                        QuizOption(text: "The speaker effectively conveyed their ideas", isCorrect: true),
                        QuizOption(text: "The response lacked coherence", isCorrect: false),
                        QuizOption(text: "Grammar usage was inconsistent", isCorrect: false),
                        QuizOption(text: "Vocabulary range was limited", isCorrect: false)
                    ]
                    
                    let botMessage = ChatMessage(
                        content: response,
                        isMe: false,
                        timestamp: Date(),
                        quizOptions: quizOptions,
                        question: "Based on the speaking response, which statement is most accurate?"
                    )
                    
                    DispatchQueue.main.async {
                        self.messages.append(botMessage)
                        self.isLoading = false
                    }
                } catch {
                    print("LLM chat error: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func playAudioMessage(url: URL) {
        if self.isPlaying {
            audioRecorder.stopPlayback()
            self.isPlaying = false
        } else {
            audioRecorder.playAudio(url: url) {
                self.isPlaying = false
            }
            self.isPlaying = true
        }
    }
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Int(-startTime.timeIntervalSinceNow)
        return String(format: "%d:%02d", duration / 60, duration % 60)
    }

    var body: some View {
        VStack {
            Text("当前角色: \(roleId)")
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message,
                                             isSpeaking: $isSpeaking,
                                             onSpeakToggle: { text in
                                toggleSpeaking(text: text)
                            },
                            audioRecorder: audioRecorder)
                            .id(message.id)
                        }
                    }
                    .padding()
                    .onChange(of: messages) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // 录音状态显示
            if isRecording {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        // Add cancel indicator icon
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(cancelHighlighted ? .red : .gray)
                            .animation(.easeInOut, value: cancelHighlighted)
                        
                        Text("松开发送，上滑取消")
                            .foregroundColor(cancelHighlighted ? .red : .gray)
                        if let startTime = recordingStartTime {
                            Text(formatDuration(from: startTime))
                                .foregroundColor(.gray)
                                .monospacedDigit()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // 底部输入区域
            HStack {
                Button(action: {
                    showPromptPopover = true
                }) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                }
                .popover(isPresented: $showPromptPopover) {
                    PromptListView()
                }
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 修改录音按钮，添加 loading 状态
                ZStack {
                    // 外圈动画
                    Circle()
                        .stroke(isRecording ? Color.red : Color.clear, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)
                    
                    // 主按钮
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(1.5)
                                } else {
                                    Image(systemName: isRecording ? "waveform" : "mic.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(isRecording ? .red : .blue)
                                }
                            }
                        )
                        .scaleEffect(isRecording ? 0.9 : 1.0)
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .onEnded { _ in
                            startRecording()
                        }
                        .simultaneously(with: DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Update cancel highlight based on drag position
                                withAnimation {
                                    cancelHighlighted = value.translation.height < -50
                                }
                            }
                            .onEnded { value in
                                if value.translation.height < -50 {
                                    cancelRecording()
                                } else {
                                    stopRecording()
                                }
                                // Reset cancel highlight
                                cancelHighlighted = false
                            })
                )
                .animation(.spring(response: 0.3), value: isRecording)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            // 在 ChatDetailView 中添加警告对话框
            .alert("需要权限", isPresented: $showingPermissionAlert) {
                Button("打开设置") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("请在设置中允许使用麦克风和语音识别功能。\n\n需要开启:\n1. 麦克风权限\n2. 语音识别权限")
            }
        }
        .navigationTitle(chatSession.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            // 在视图加载时调用 model.chat
            // Task {
            //     do {
            //         let response = try await model.chat(content: "Let's begin.")
            //         let botMessage = ChatMessage(
            //             content: response,
            //             isMe: false,
            //             timestamp: Date(),
            //             nodes: nil,
            //             audioURL: nil,
            //             quizOptions: nil,
            //             question: nil
            //         )
            //         self.messages.append(botMessage)
            //         self.toggleSpeaking(text: response)
            //     } catch {
            //         print("Initial chat error: \(error)")
            //     }
            // }
        }
        .onDisappear {
            // 在视图消失时清理音频资源
            audioRecorder.cleanup()
        }
    }
}

struct PromptListView: View {
    let prompts = [
        "请用简单的语言解释",
        "帮我总结一下要点",
        "给我一些具体的例子",
        "这个问题可以换个角度思考吗？",
        "能详细说明一下吗？"
    ]
    
    var body: some View {
        List(prompts, id: \.self) { prompt in
            Button(action: {
                // TODO: 实现点击提示文本后的操作
                // 可以将文本复制到输入框或直接发送
            }) {
                Text(prompt)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 250, height: 300)
    }
}

// 录音管理类
class AudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var playbackCompleted: (() -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default,
                                       options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }
    
    func startRecording() {
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
            audioRecorder?.record()
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        audioRecorder?.stop()
        // 生成唯一的文件名
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).m4a"
        let permanentURL = documentsPath.appendingPathComponent(fileName)
        
        // 将临时录音文件移动到永久位置
        if let originalURL = recordingURL {
            try? FileManager.default.moveItem(at: originalURL, to: permanentURL)
            completion(permanentURL)
        } else {
            completion(nil)
        }
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
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
            
            // 保存完成回调
            self.playbackCompleted = onComplete
        } catch {
            print("Failed to play audio: \(error)")
            onComplete()
        }
    }
    
    // AVAudioPlayerDelegate 方法
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackCompleted?()
            self?.playbackCompleted = nil
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackCompleted?()
        playbackCompleted = nil
    }
    
    func cleanup() {
        // 停止录音
        audioRecorder?.stop()
        audioRecorder = nil
        
        // 停止播放
        audioPlayer?.stop()
        audioPlayer = nil
        playbackCompleted = nil
        
        // 清理音频会话
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        #endif
    }
}

// 由于 ChatMessage 包含了 MsgTextNode，我们也需要让 MsgTextNode 遵循 Equatable
struct MsgTextNode: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let type: String
    let error: TextError?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case type
        case error
    }
}

// TextError 也需要遵循 Equatable
struct TextError: Codable, Equatable {
    let type: String
    let reason: String
    let correction: String
}

// 添加一个新的 WavyLine Shape
struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let wavelength = 6.0 // 波长
        let amplitude = height // 波的高度
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // 创建波浪形状
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let y = sin(relativeX * .pi * 2) * amplitude / 2 + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// 添加三角形箭头形状
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// 添加字典弹窗视图
private struct DictionaryPopoverView: View {
    let word: String
    @State private var definition: String = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word)
                .font(.headline)
            
            Divider()
            
            Text(definition)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 280)
        .padding()
        .onAppear {
            // 这里可以调用字典 API 获取释义
            // 暂时使用模拟数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                definition = "1. (n.) a sample definition\n2. (v.) another meaning of the word"
            }
        }
    }
}

// 修改 MessageTextNodeView 结构体
private struct MessageTextNodeView: View {
    let node: MsgTextNode
    let isMe: Bool
    @State private var isShowingTooltip = false
    @State private var isShowingDictionary = false
    
    var body: some View {
        Text(node.text)
            .foregroundColor(isMe ? .white : .black)
            .if(node.error != nil) { view in
                view
                    .overlay(
                        WavyLine()
                            .stroke(underlineColor, lineWidth: 1)
                            .frame(height: 2)
                            .offset(y: 10)
                    )
            }
            .onTapGesture {
                if !node.text.trimmingCharacters(in: .whitespaces).isEmpty {
                    isShowingDictionary = true
                }
            }
            .popover(isPresented: $isShowingDictionary) {
                DictionaryPopoverView(word: node.text.trimmingCharacters(in: .whitespaces))
            }
    }
    
    private var underlineColor: Color {
        print("node.error: \(String(describing: node.error?.type))")
        guard node.error != nil else { return .clear }
        switch node.error?.type {
        case "error": return .red
        case "grammar": return .yellow
        default: return .clear
        }
    }
}

// 翻译文本视图
private struct TranslationView: View {
    let text: String
    let isMe: Bool
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(isMe ? .white.opacity(0.8) : .gray)
            .padding(.top, 4)
    }
}

// 消息内容视图
private struct MessageContentView: View {
    let nodes: [MsgTextNode]
    let isMe: Bool
    let translatedText: String
    let isShowingTranslation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FlowLayout(spacing: 0) { 
                ForEach(nodes) { node in
                    MessageTextNodeView(node: node, isMe: isMe)
                }
            }
            
            if isShowingTranslation && !translatedText.isEmpty {
                TranslationView(text: translatedText, isMe: isMe)
            }
        }
    }
}

// 自定义流式布局容器
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? .infinity
        
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width + spacing > maxWidth {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var isShowingActions = false
    @State private var isShowingTranslation = false
    @State private var translatedText: String = ""
    @State private var isPlaying = false
    @State private var isBlurred: Bool
    @Binding var isSpeaking: Bool
    let onSpeakToggle: (String) -> Void
    let audioRecorder: AudioRecorder
    @State private var localQuizOptions: [QuizOption]?
    
    init(message: ChatMessage, 
         isSpeaking: Binding<Bool>, 
         onSpeakToggle: @escaping (String) -> Void,
         audioRecorder: AudioRecorder) {
        self.message = message
        _isBlurred = State(initialValue: !message.isMe)
        _isSpeaking = isSpeaking
        self.onSpeakToggle = onSpeakToggle
        self.audioRecorder = audioRecorder
        _localQuizOptions = State(initialValue: message.quizOptions)
    }
    
    var nodes: [MsgTextNode] {
        var nodeId = 0
        var result: [MsgTextNode] = []
        
        let words = message.content.split(whereSeparator: { $0.isWhitespace }, omittingEmptySubsequences: false)
        for word in words {
            nodeId += 1
            let node = MsgTextNode(
                id: nodeId,
                text: String(word),
                type: word.allSatisfy { $0.isWhitespace } ? "space" : "text",
                error: nil
            )
            result.append(node)
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if message.isMe { Spacer() }
                
                VStack(alignment: message.isMe ? .trailing : .leading) {
                    MessageContentView(
                        nodes: nodes,
                        isMe: message.isMe,
                        translatedText: translatedText,
                        isShowingTranslation: isShowingTranslation
                    )
                    .padding(12)
                    .background(message.isMe ? Color.blue.opacity(0.8) : Color(uiColor: .systemGray5))
                    .cornerRadius(16)
                     .if(isBlurred && !message.isMe) { view in
                        view.blur(radius: 5)
                    }
                    
                    // 操作按钮区域
                    if message.audioURL != nil || !message.isMe {
                        HStack(spacing: 8) {
                            if !message.isMe { Spacer() }
                            
                            // 显示按钮（仅对非用户消息显示）
                            if !message.isMe {
                                Button(action: {
                                    isBlurred.toggle()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isBlurred ? "eye.slash.fill" : "eye.fill")
                                        Text(isBlurred ? "显示" : "隐藏")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // 播放录音按钮（仅对用户消息显示）
                            if message.isMe, let _ = message.audioURL {
                                Button(action: {
                                    if let url = message.audioURL {
                                        if isPlaying {
                                            audioRecorder.stopPlayback()
                                            isPlaying = false
                                        } else {
                                            audioRecorder.playAudio(url: url) {
                                                isPlaying = false
                                            }
                                            isPlaying = true
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                        Text(isPlaying ? "停止" : "回放")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // 文本朗读按钮（仅对非用户消息显示）
                            if !message.isMe {
                                Button(action: {
                                    onSpeakToggle(message.content)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                        Text(isSpeaking ? "停止" : "朗读")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            if message.isMe { Spacer() }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                    }
                    
                    ErrorIndicatorView(node: nodes.first)
                }
                
                if !message.isMe { Spacer() }
            }
            
            // 答题卡片（独立于气泡）
            if let options = localQuizOptions, let question = message.question {
                QuizCardView(
                    question: question,
                    options: Binding(
                        get: { options },
                        set: { localQuizOptions = $0 }
                    )
                )
                .frame(maxWidth: .infinity)
            }
        }
        .confirmationDialog(
            "操作选项",
            isPresented: $isShowingActions,
            actions: {
                Button("保存") { saveMessage() }
                Button("朗读") { onSpeakToggle(message.content) }
                Button("翻译") { translateMessage() }
                Button("优化") { optimizeMessage() }
                Button("查错") { checkErrors() }
                Button("取消", role: .cancel) {}
            }
        )
    }
    
    // 操作函数
    func saveMessage() {
        // 实现保存逻辑
        // NSPasteboard.general.clearContents()
        // NSPasteboard.general.setString(message.content, forType: .string)
    }
    
    func translateMessage() {
        // 模拟翻译
        isShowingTranslation = true
        translatedText = "Translated text will appear here"
        // 实际应该调用翻译 API
    }
    
    func optimizeMessage() {
        // 实现优化逻辑
    }
    
    func checkErrors() {
        // 实现查错逻辑
    }
}

// 用于条件修饰符的 View 扩展
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// 错误提示视图
private struct ErrorIndicatorView: View {
    let node: MsgTextNode?
    
    var body: some View {
        Group {
            if let node = node,
            node.error != nil &&  node.error?.type == "error" {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(node.error?.reason ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                    if let correction = node.error?.correction, !correction.isEmpty {
                        Text("建议：\(correction)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }
}

// 修改 QuizOption 结构体
struct QuizOption: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isCorrect: Bool
    var isSelected: Bool = false
    var hasBeenSelected: Bool = false // 新增：记录是否被选择过
}

// 更新 QuizCardView 组件
struct QuizCardView: View {
    let question: String
    @Binding var options: [QuizOption]
    @State private var selectedOption: UUID?
    @State private var showResult: Bool = false
    @State private var attempts: Int = 0
    
    // 计算网格布局
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 问题部分
            VStack(alignment: .leading, spacing: 8) {
                Text("评估")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(question)
                    .font(.headline)
            }
            
            // 选项网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options) { option in
                    Button(action: {
                        handleOptionSelection(option)
                    }) {
                        HStack {
                            Text(option.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer()
                            if option.hasBeenSelected {
                                Image(systemName: option.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(option.isCorrect ? .green : .red)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(getBackgroundColor(for: option))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(option.hasBeenSelected && !option.isCorrect)
                }
            }
            
            // 尝试次数提示
            if attempts > 0 {
                HStack {
                    Image(systemName: "info.circle")
                    Text(attempts == 1 ? "第一次尝试" : "第 \(attempts) 次尝试")
                    if let option = options.first(where: { $0.hasBeenSelected && $0.isCorrect }) {
                        Text("- 答对了！")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func handleOptionSelection(_ option: QuizOption) {
        attempts += 1
        
        // 更新选项状态
        if option.isCorrect {
            // 如果选择正确，显示正确标记
            selectedOption = option.id
            showResult = true
        } else {
            // 如果选择错误，只标记当前选项为错误
            selectedOption = option.id
        }
        
        // 标记当前选项为已选择
        if let index = options.firstIndex(where: { $0.id == option.id }) {
            options[index].hasBeenSelected = true
        }
    }
    
    private func getBackgroundColor(for option: QuizOption) -> Color {
        if option.hasBeenSelected {
            if option.isCorrect {
                return Color.green.opacity(0.1)
            } else {
                return Color.red.opacity(0.1)
            }
        }
        return Color(UIColor.systemBackground)
    }
}

