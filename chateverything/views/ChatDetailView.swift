import SwiftUI
import Foundation
import AVFoundation
import Speech
import LLM


class LocalChatBox: ObservableObject, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let isMe: Bool
    var type: String

    @Published var controller: ChatBoxBiz?
    // var type: String {
    //     get { controller?.type ?? "unkown" }
    // }

    @Published var audioURL: URL?
    @Published var isLoading: Bool = true
    @Published var isBlurred: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isSpeaking: Bool = false
    
    init(id: UUID = UUID(), timestamp: Date = Date(), isMe: Bool, isLoading: Bool = true, type: String, audioURL: URL? = nil, box: ChatBoxBiz) {
        self.id = id
        self.timestamp = timestamp
        self.isMe = isMe
        self.isLoading = isLoading
        self.type = type
        self.audioURL = audioURL
        self.controller = box
    }

    static func ==(first: LocalChatBox, second: LocalChatBox) -> Bool {
        return first.id == second.id
    }
}

class ChatDetailViewModel: ObservableObject {
    let store: ChatStore
    let session: ChatSessionBiz
    let role: RoleBiz

    @Published var loading = true
    @Published var disabled = true
    @Published var roleDetailVisible = false
    @Published var promptPopoverVisible = false
    @Published var permissionAlertVisible = false
    @Published var error: String?
    @Published var messages: [LocalChatBox] = [
        LocalChatBox(
            id: UUID(),
            timestamp: Date(),
            isMe: true,
            isLoading: false,
            type: "tip",
            box: ChatBoxBiz(
                id: UUID(),
                type: "tip",
                payload_id: UUID(),
                created_at: Date(),
                session_id: UUID(),
                payload: ChatPayload.tip(ChatTipBiz(title: "提示", content: "长按录音按钮，开始录音", type: "tip"))
            )
        )   
    ]

        
    init?(id: UUID, store: ChatStore) {
        self.store = store

        let session = ChatSessionBiz.from(id: id, in: store)
        guard let session = session else {
            return nil
        }
        self.session = session
        self.role = session.role
    }

    func showPermissionAlert() {
        self.permissionAlertVisible = true
    }
    func showRoleDetail() {
        self.roleDetailVisible = true
    }
    func showPromptPopover() {
        self.promptPopoverVisible = true
    }
    func appendMessage(message: LocalChatBox) {
        self.messages.append(message)
    }
}

// 聊天详情页面
struct ChatDetailView: View {
    var sessionId: UUID
    var store: ChatStore
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: ChatDetailViewModel
    @StateObject private var recorder: AudioRecorder
    private var speaker = TTSManager.shared

    @State private var toastMessage: String?
    
    init(sessionId: UUID, store: ChatStore) {
        self.sessionId = sessionId
        self.store = store
        _model = StateObject(wrappedValue: ChatDetailViewModel(id: sessionId, store: store)!)
        _recorder = StateObject(wrappedValue: AudioRecorder())
    }

    // 将回调设置移到 onAppear
    private func setupRecorderCallbacks() {
        // 设置录音完成的回调
        self.recorder.onCompleted = { url in
            print("complete audio recording, the url: \(url)")
            
            // 开始语音识别
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            
            guard let recognizer = recognizer, recognizer.isAvailable else {
                self.model.showPermissionAlert()
                return
            }
            
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self.recognizeSpeech(url: url)
                    case .denied, .restricted, .notDetermined:
                        self.model.showPermissionAlert()
                    @unknown default:
                        // self.toastMessage = "未知的语音识别授权状态"
                        print("Unknown speech recognition authorization status")
                    }
                }
            }
        }
        
        self.recorder.onBegin = {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // 已获得录音权限，无需操作
                    } else {
                        self.model.showPermissionAlert()
                    }
                }
            }
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
    
    private func toggleSpeaking(message: LocalChatBox) {
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
        request.shouldReportPartialResults = false
        
        recognizer.recognitionTask(with: request) {  result, error in
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
        // guard let viewModel = self.model else {
        //     return
        // }
        if recognizedText.isEmpty {
            print("recognizedText is empty")
            return
        }
        print("handleRecognizedSpeech \(recognizedText)")
        let viewModel = self.model
            let userMessage = LocalChatBox(
                id: UUID(),
                timestamp: Date(),
                isMe: true,
                isLoading: false,
                type: "message",
                audioURL: audioURL,
                box: ChatBoxBiz(
                    id: UUID(),
                    type: "message",
                    payload_id: UUID(),
                    created_at: Date(),
                    session_id: viewModel.session.id,
                    payload: ChatPayload.message(ChatMessageBiz2(text: recognizedText, nodes: []))
                )
            )
            viewModel.appendMessage(message: userMessage)
            let loadingMessage = LocalChatBox(
                id: UUID(),
                timestamp: Date(),
                isMe: false,
                isLoading: true,
                type: "message",
                audioURL: nil,
                box: ChatBoxBiz(
                    id: UUID(),
                    type: "message",
                    payload_id: UUID(),
                    created_at: Date(),
                    session_id: viewModel.session.id,
                    payload: ChatPayload.message(ChatMessageBiz2(text: "...", nodes: []))
                )
            )
            viewModel.appendMessage(message: loadingMessage)

            Task {
                do {
                    let response = try await viewModel.session.llm.chat(content: recognizedText)
                    print("before update box isLoading")
                    if let loadingMessage = viewModel.messages.last {
                        loadingMessage.controller?.setPayload(
                                payload: ChatPayload.message(ChatMessageBiz2(text: response, nodes: []))
                            )
                            print("before update box isLoading !!")
                            loadingMessage.isLoading = false
                            // toggleSpeaking(message: loadingMessage)
                    }
                } catch {
                    print("LLM chat error: \(error)")
                    // Remove loading message on error
                    if let loadingMessage = viewModel.messages.last {
                        print("before update box isLoading")
                        loadingMessage.isLoading = false
                        loadingMessage.type = "error"
                        loadingMessage.controller?.setPayload(
                            payload: ChatPayload.error(ChatErrorBiz(error: "发生了错误"))
                        )
                    }
                }
            }
    }
    
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Int(-startTime.timeIntervalSinceNow)
        return String(format: "%d:%02d", duration / 60, duration % 60)
    }

    func onMounted() {
        
    }

    var body: some View {
        ChatDetailContentView(
            recorder: recorder,
            model: model,
            onDismiss: { dismiss() },
            onSpeakToggle: toggleSpeaking
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ChatDetailToolbarButton(model: model)
            }
        }
        .sheet(isPresented: $model.roleDetailVisible) {
            let role = self.model.role
            let session = self.model.session
            RoleDetailView(role: role, session: session)
        }
        .onAppear {
            setupRecorderCallbacks()
        }
        .onDisappear {
            self.recorder.cleanup()
        }
    }
}

// 拆分出主要内容视图
private struct ChatDetailContentView: View {
    let recorder: AudioRecorder
    let model: ChatDetailViewModel
    let onDismiss: () -> Void
    let onSpeakToggle: (LocalChatBox) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack {
                ChatMessageList(
                    model: model,
                    recorder: recorder,
                    onSpeakToggle: onSpeakToggle
                )
            }
            
            // Input bar overlay
            VStack {
                Spacer()
                InputBarView(recorder: recorder)
                    .background(
                        Rectangle()
                            .fill(Color.white.opacity(0))
                            .edgesIgnoringSafeArea(.bottom)
                    )
            }
            
            // Error overlay if needed
            if let error = model.error {
                ErrorOverlayView(error: error, onDismiss: onDismiss)
            }
        }
    }
}

// 拆分出消息列表视图
private struct ChatMessageList: View {
    @ObservedObject var model: ChatDetailViewModel
    let recorder: AudioRecorder
    let onSpeakToggle: (LocalChatBox) -> Void
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 12) {
                    ForEach(model.messages) { box in
                        ChatBoxView(
                            box: box,
                            recorder: recorder,
                            onSpeakToggle: onSpeakToggle
                        )
                        .id(box.id)
                    }
                }
                .padding()
                .padding(.bottom, 180) // Add padding for InputBarView
                .onChange(of: model.messages) { _ in
                    if let lastMessage = model.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// 拆分出工具栏按钮
private struct ChatDetailToolbarButton: View {
    let model: ChatDetailViewModel
    
    var body: some View {
        Button(action: {
            model.showRoleDetail()
        }) {
            Image(systemName: "ellipsis")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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

struct TextNodeView: View {
    let node: MsgTextNode
    let color: Color
    var onTap: (MsgTextNode) -> Void
    
    var body: some View {
        Text(node.text)
            .foregroundColor(color)
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
                    onTap(node)
                }
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


// 消息内容视图
private struct MessageContentView: View {
    let box: LocalChatBox
    let data: ChatMessageBiz2

    var body: some View {
        HStack {
            if box.isMe { Spacer() }
            
            if box.isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("思考中...")
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color(uiColor: .systemGray5))
                .cornerRadius(16)
            } else {
                VStack(alignment: box.isMe ? .trailing : .leading, spacing: 4) {
                    if !data.ok {
                        Text(data.text)
                    } else {
                        FlowLayout(spacing: 0) { 
                            ForEach(data.nodes) { node in
                                TextNodeView(node: node, color: box.isMe ? .white : .black, onTap: { node in
                                    print("node: \(node)")
                                })
                            }
                        }
                    }
                }
                .padding(12)
                .background(box.isMe ? Color.blue.opacity(0.8) : Color(uiColor: .systemGray5))
                .cornerRadius(16)
            }
            
            if !box.isMe { Spacer() }
        }
    }
}
private struct AudioContentView: View {
    let box: LocalChatBox
    let data: ChatAudioBiz
    let recorder: AudioRecorder
    var onSpeakToggle: (LocalChatBox) -> Void

    var body: some View {
        Text("Audio Content")
        if data.url != nil || !box.isMe {
            if box.isMe {
                UserMessageActions(
                    recorder: self.recorder,
                    box: self.box
                )
            } else {
                BotMessageActions(
                    box: box,
                    // isBlurred: box.isBlurred,
                    onSpeakToggle: { box in
                        onSpeakToggle(box)
                    }
                )
            }
        }
    }
}

// 更新 TipContentView 组件
private struct TipContentView: View {
    let data: ChatTipBiz
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            Text(data.content)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// 在 ChatBoxView 的 body 中更新条件分支
struct ChatBoxView: View {
    @ObservedObject var box: LocalChatBox
    var recorder: AudioRecorder
    let onSpeakToggle: (LocalChatBox) -> Void
    @State private var isShowingActions = false

    // 操作函数
    func saveMessage() {
        // 实现保存逻辑
        // NSPasteboard.general.clearContents()
        // NSPasteboard.general.setString(message.content, forType: .string)
    }
    
    func translateMessage() {
        // 模拟翻译
//        isShowingTranslation = true
//        translatedText = "Translated text will appear here"
        // 实际应该调用翻译 API
    }
    
    func optimizeMessage() {
        // 实现优化逻辑
    }
    
    func checkErrors() {
        // 实现查错逻辑
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if box.type == "error" {
                if case let .error(data) = box.controller?.payload {
                    ErrorContentView(data: data)
                }
            } else if box.type == "audio" {
                if case let .audio(data) = box.controller?.payload {
                    AudioContentView(
                        box: box,
                        data: data,
                        recorder: recorder,
                        onSpeakToggle: onSpeakToggle
                    )
                }
            } else if box.type == "message" {
                if case let .message(data) = box.controller?.payload {
                    MessageContentView(box: box, data: data)
                }
            } else if box.type == "quiz" {
                if case let .puzzle(data) = box.controller?.payload {
                    QuizContentView(data: data)
                        .frame(maxWidth: .infinity)
                }
            } else if box.type == "tip" {
                if case let .tip(data) = box.controller?.payload {
                    TipContentView(data: data)
                }
            }
        }
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
private struct ErrorContentView: View {
    let data: ChatErrorBiz

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("出错了")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(data.error)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// 更新 QuizContentView 组件
struct QuizContentView: View {
    @ObservedObject var data: ChatPuzzleBiz

    @State private var selectedOption: UUID?
    @State private var showResult: Bool = false
    @State private var attempts: Int = 0
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private func getBackgroundColor(for option: ChatPuzzleOption) -> Color {
        if data.isSelected(option: option) {
            if data.isCorrect(option: option) {
                return Color.green.opacity(0.1)
            } else {
                return Color.red.opacity(0.1)
            }
        }
        return Color(UIColor.systemBackground)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 问题部分
            VStack(alignment: .leading, spacing: 8) {
                Text("评估")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(data.question)
                    .font(.headline)
            }
            
            // 选项网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(data.options) { option in
                    Button(action: {
//                        handleOptionSelection(option)
                    }) {
                        HStack {
                            Text(option.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer()
                            if data.isSelected(option: option) {
                                Image(systemName: data.isCorrect(option: option) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(data.isCorrect(option: option) ? .green : .red)
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
                    .disabled(data.isSelected(option: option) && !data.isCorrect(option: option))
                }
            }
            
            // 尝试次数提示
            if data.attempts > 0 {
                HStack {
                    Image(systemName: "info.circle")
                    Text(data.attempts == 1 ? "第一次尝试" : "第 \(data.attempts) 次尝试")
                    if data.isCorrect {
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
}


struct RecordButton: View {
    @ObservedObject var recorder: AudioRecorder
    @State private var scale: CGFloat = 1.0
    @State private var cancelHighlighted: Bool = false
    var isLoading: Bool = false
    
    var body: some View {
        ZStack(alignment: .center) {
            // 录音状态显示
            if recorder.isRecording {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(cancelHighlighted ? .red : .gray)
                        .animation(.easeInOut, value: cancelHighlighted)
                    
                    Text("松开发送，上滑取消")
                        .font(.system(size: 14))
                        .foregroundColor(cancelHighlighted ? .red : .gray)
                }
                .offset(y: -140)
            }
            
            // 录音按钮
            ZStack {
                // 外圈动画
                Circle()
                    .stroke(recorder.isRecording ? (cancelHighlighted ? Color.red : Color.green) : Color.clear, lineWidth: 4)
                    .frame(width: 128, height: 128)
                    .scaleEffect(scale)
                
                // 主按钮
                Circle()
                    .fill(recorder.isRecording ? (cancelHighlighted ? Color.red.opacity(0.2) : Color.green.opacity(0.2)) : Color.blue.opacity(0.1))
                    .frame(width: 108, height: 108)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(1.8)
                            } else {
                                Image(systemName: recorder.isRecording ? "waveform" : "mic.circle.fill")
                                    .font(.system(size: 68))
                                    .foregroundColor(recorder.isRecording ? (cancelHighlighted ? .red : .green) : .blue)
                            }
                        }
                    )
                    .scaleEffect(recorder.isRecording ? 0.9 : 1.0)
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onEnded { _ in
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                            scale = 1.2
                        }
                        recorder.startRecording()
                    }
                    .simultaneously(with: DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            withAnimation {
                                cancelHighlighted = value.translation.height < -50
                            }
                        }
                        .onEnded { value in
                            withAnimation {
                                scale = 1.0
                            }
                            if value.translation.height < -50 {
                                recorder.cancelRecording()
                            } else {
                                recorder.stopRecording() { url in
                                    print("complete audio recoding, the url: \(String(describing: url))")
                                }
                            }
                            cancelHighlighted = false
                        })
            )
            .animation(.spring(response: 0.3), value: recorder.isRecording)
        }
    }
}

// 更新 InputBarView 以移除重复的录音状态显示
struct InputBarView: View {
    @ObservedObject var recorder: AudioRecorder
    
    var body: some View {
        ZStack {
            // Left buttons
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 24))
                }
                .frame(width: 50, height: 50) // 固定尺寸确保圆形
                .background(Color.purple)
                .clipShape(Circle())
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(Color.purple)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            
            // Centered RecordButton
            RecordButton(recorder: recorder)
                .frame(maxWidth: .infinity)
            
            // Right button
            HStack {
                Button(action: {}) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(Color.purple)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing)
        }
        .frame(height: 180)
    }
}

private struct UserMessageActions: View {
    let recorder: AudioRecorder

    @ObservedObject var box: LocalChatBox
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            if let _ = box.audioURL {
                Button(action: {
                    if let url = box.audioURL {
                        if box.isPlaying {
                            recorder.stopPlayback()
                            box.isPlaying = false
                        } else {
                            recorder.playAudio(url: url) {
                                box.isPlaying = false
                            }
                            box.isPlaying = true
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: box.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        Text(box.isPlaying ? "停止" : "回放")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

private struct BotMessageActions: View {
    @ObservedObject var box: LocalChatBox
    
    let onSpeakToggle: (LocalChatBox) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            Button(action: {
                box.isBlurred.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: box.isBlurred ? "eye.slash.fill" : "eye.fill")
                    Text(box.isBlurred ? "显示" : "隐藏")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                onSpeakToggle(box)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: box.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    Text(box.isSpeaking ? "停止" : "朗读")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}


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
