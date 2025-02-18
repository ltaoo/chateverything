import SwiftUI
import AVFoundation
import Speech
import LLM

// 聊天消息模型
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isMe: Bool
    let timestamp: Date
    var nodes: [MsgTextNode]?
    var audioURL: URL? // 新增录音 URL
    var isBlurred: Bool // 移除默认值,在初始化时设置
    
    init(content: String, isMe: Bool, timestamp: Date, nodes: [MsgTextNode]? = nil, audioURL: URL? = nil) {
        self.content = content
        self.isMe = isMe
        self.timestamp = timestamp
        self.nodes = nodes
        self.audioURL = audioURL
        self.isBlurred = !isMe // 非用户消息默认模糊
    }
    
    // 实现 Equatable 协议
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isMe == rhs.isMe &&
        lhs.timestamp == rhs.timestamp &&
        lhs.nodes == rhs.nodes &&
        lhs.audioURL == rhs.audioURL &&
        lhs.isBlurred == rhs.isBlurred
    }
}

let prompt = "You are an IELTS speaking examiner. Conduct a simulated IELTS speaking test by asking questions one at a time. After receiving each response with pronunciation scores from speech recognition, evaluate the answer and proceed to the next question. Do not ask multiple questions at once. After all sections are completed, provide a comprehensive evaluation and an estimated IELTS speaking band score. Begin with the first question.";

// 聊天详情页面
struct ChatDetailView: View {
    let chatSession: ChatSession
    let model: LLMService
    @State private var isPlaying = false
    
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(content: prompt, isMe: false, timestamp: Date()),
    ]
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var scale: CGFloat = 1.0
    @State private var isLoading = false
    @State private var cancelHighlighted = false
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingPermissionAlert = false
    private let synthesizer = AVSpeechSynthesizer()
    
    private func startRecording() {
        #if os(iOS)
        // 检查麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    self.isRecording = true
                    self.recordingStartTime = Date()
                    // 开始录音动画
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                        self.scale = 1.2
                    }
                    // 开始录音
                    self.audioRecorder.startRecording()
                    
                    // 使用 Timer 更新录音时间
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak timer = Timer()] timer in
                        if !self.isRecording {
                            timer.invalidate()
                        } else {
                            // 更新 recordingStartTime 来触发视图更新
                            self.recordingStartTime = Date(timeInterval: 0, since: self.recordingStartTime ?? Date())
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showingPermissionAlert = true
                }
            }
        }
        #else
        // macOS implementation
        self.isRecording = true
        self.recordingStartTime = Date()
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
            self.scale = 1.2
        }
        self.audioRecorder.startRecording()
        
        // 使用 Timer 更新录音时间
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak timer = Timer()] timer in
            if !self.isRecording {
                timer?.invalidate()
            } else {
                // 更新 recordingStartTime 来触发视图更新
                self.recordingStartTime = Date(timeInterval: 0, since: self.recordingStartTime ?? Date())
            }
        }
        #endif
    }
    
    private func stopRecording() {
        isRecording = false
        recordingStartTime = nil
        scale = 1.0
        
        // 停止录音并进行语音识别
        audioRecorder.stopRecording { url in
        print("complete audio recoding, the url: \(url)")
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
    
    private func recognizeSpeech(url: URL) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            guard let result = result else {
                print("Recognition failed with error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            if result.isFinal {
                let recognizedText = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    let message = ChatMessage(content: recognizedText, 
                                            isMe: true, 
                                            timestamp: Date(),
                                            nodes: nil,
                                            audioURL: url)
                    self.messages.append(message)
                    self.isLoading = true
                }
                
                Task {
                    do {
                        let response = try await self.model.chat(content: recognizedText)
                        
                        // 设置音频会话
                        #if os(iOS)
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback)
                            try AVAudioSession.sharedInstance().setActive(true)
                        } catch {
                            print("Failed to set audio session: \(error)")
                        }
                        #endif
                        
                        DispatchQueue.main.async {
                            // 先添加消息
                            let botMessage = ChatMessage(content: response, 
                                                       isMe: false, 
                                                       timestamp: Date(),
                                                       nodes: nil,
                                                       audioURL: nil)
                            self.messages.append(botMessage)
                            self.isLoading = false
                            
                            // 配置并播放语音
                            let utterance = AVSpeechUtterance(string: response)
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            utterance.rate = 0.5
                            utterance.pitchMultiplier = 1.0
                            utterance.volume = 1.0
                            
                            // 停止任何正在播放的语音
                            if self.synthesizer.isSpeaking {
                                self.synthesizer.stopSpeaking(at: .immediate)
                            }
                            
                            // 开始播放新的语音
                            self.synthesizer.speak(utterance)
                        }
                    } catch {
                        print("LLM chat error: \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Int(-startTime.timeIntervalSinceNow)
        return String(format: "%d:%02d", duration / 60, duration % 60)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // 发送用户消息
        let userMessage = ChatMessage(content: messageText, isMe: true, timestamp: Date())
        messages.append(userMessage)
        
        // 调用 Rust 代码处理消息
        // let response = ChatCore.sendMessage(messageText)
        let response = "hello"
        
        // 添加响应消息
        let botMessage = ChatMessage(content: response, isMe: false, timestamp: Date())
        messages.append(botMessage)
        
        messageText = ""
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
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
                Button("确定") {}
            } message: {
                Text("请在设置中允许使用麦克风和语音识别功能")
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
            //         let response = try await model.chat(content: prompt)
            //         let botMessage = ChatMessage(content: response, 
            //                                    isMe: false, 
            //                                    timestamp: Date())
            //         messages.append(botMessage)
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
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
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

// 修改 MessageTextNodeView 结构体
private struct MessageTextNodeView: View {
    let node: MsgTextNode
    let isMe: Bool
    @State private var isShowingTooltip = false
    
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
                isShowingTooltip.toggle()
            }
            .onAppear {
                // 点击其他区域时关闭 tooltip
              
            }
    }
    
    private var underlineColor: Color {
        print("node.error: \(node.error?.type)")
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
        
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width + spacing > proposal.width! {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: proposal.width!, height: totalHeight)
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
    @State private var isBlurred: Bool // 新增状态
    let synthesizer = AVSpeechSynthesizer()
    @StateObject private var audioRecorder = AudioRecorder()
    
    init(message: ChatMessage) {
        self.message = message
        // 初始化 isBlurred 状态
        _isBlurred = State(initialValue: !message.isMe) // 修改这里
    }
    
    var nodes: [MsgTextNode] {
        // 将消息内容按空格分割，并保留空格作为独立节点
        var nodeId = 0
        var result: [MsgTextNode] = []
        
        let words = message.content.split(includesSeparators: true) { $0.isWhitespace }
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
        HStack {
            if message.isMe { Spacer() }
            
            VStack(alignment: message.isMe ? .trailing : .leading) {
                // 消息气泡
                MessageContentView(
                    nodes: nodes,
                    isMe: message.isMe,
                    translatedText: translatedText,
                    isShowingTranslation: isShowingTranslation
                )
                .padding(12)
                .background(message.isMe ? Color.blue.opacity(0.8) : Color(uiColor: .systemGray5))
                .cornerRadius(16)
                .if(isBlurred && !message.isMe) { view in // 修改这里
                    view.blur(radius: 5)
                }
                
                // 操作按钮区域
                if message.audioURL != nil || !message.isMe {
                    HStack(spacing: 8) {
                        if !message.isMe { Spacer() }
                        
                        // 显示按钮（仅对非用户消息显示）
                        if !message.isMe { // 修改这里
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
                                speakMessage()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("朗读")
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
        .confirmationDialog(
            "操作选项",
            isPresented: $isShowingActions,
            actions: {
                Button("保存") { saveMessage() }
                Button("发音") { speakMessage() }
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
    
    func speakMessage() {
        let utterance = AVSpeechUtterance(string: message.content)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        synthesizer.speak(utterance)
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
