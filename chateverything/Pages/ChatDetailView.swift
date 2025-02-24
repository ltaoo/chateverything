import SwiftUI
import Foundation
import AVFoundation
import Speech

class ChatDetailViewModel: ObservableObject {
    let config: Config
    let store: ChatStore
    @Published var session: ChatSessionBiz

    @Published var loading = true
    @Published var disabled = true
    @Published var roleDetailVisible = false
    @Published var promptPopoverVisible = false
    @Published var permissionAlertVisible = false
    @Published var error: String?
    @Published var boxes: [ChatBoxBiz] = []

    init(id: UUID, config: Config, store: ChatStore) {
        self.config = config
        self.store = store
        self.session = ChatSessionBiz(
            id: id,
            created_at: Date(),
            updated_at: Date(),
            title: "",
            avatar_uri: "",
            boxes: [],
            members: [],
            config: ChatSessionConfig(blurMsg: false, autoSpeaking: false),
            store: store
        )
    }
    func load() {
        self.session.load(id: self.session.id, config: self.config)
        self.boxes = self.session.boxes
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
    func appendMessage(box: ChatBoxBiz) {
        print("Appending message to session")
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.session.append(box: box)
        }
    }
}

// 聊天详情页面
struct ChatDetailView: View {
    var sessionId: UUID
    var store: ChatStore
    var config: Config
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: ChatDetailViewModel
    @StateObject private var recorder: AudioRecorder
    private var speaker = TTSManager.shared

    @State private var toastMessage: String?
    
    init(sessionId: UUID, config: Config) {
        self.sessionId = sessionId
        self.config = config
        self.store = config.store
        _model = StateObject(wrappedValue: ChatDetailViewModel(id: sessionId, config: config, store: config.store))
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
        request.shouldReportPartialResults = false
        
        // 获取音频时长
        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        let duration = audioPlayer?.duration ?? 0
        
        recognizer.recognitionTask(with: request) {  result, error in
            if let error = error {
                print("Recognition failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, result.isFinal else { return }
            
            let recognizedText = result.bestTranscription.formattedString
            self.handleRecognizedSpeech(recognizedText: recognizedText, audioURL: url, duration: duration)
        }
    }
    
    private func handleRecognizedSpeech(recognizedText: String, audioURL: URL, duration: TimeInterval) {
        if recognizedText.isEmpty {
            print("recognizedText is empty")
            return
        }
        // print("handleRecognizedSpeech \(recognizedText)")
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
            loading: false,
            blurred: false
        )
        viewModel.session.append(box: userMessage) { boxes in
            print("Current box count: \(boxes.count)")
            viewModel.boxes = boxes
        }

        for member in viewModel.session.members {
            if let role = member.role {
                let box = role.response(text: recognizedText, session: viewModel.session, config: config)
                viewModel.session.append(box: box) { boxes in
                    print("Current box count: \(boxes.count)")
                    viewModel.boxes = boxes
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
            model: model,
            recorder: recorder,
            onDismiss: { dismiss() },
            onSpeakToggle: toggleSpeaking
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ChatDetailToolbarButton(model: model)
            }
        }
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

// 拆分出主要内容视图
private struct ChatDetailContentView: View {
    let model: ChatDetailViewModel
    let recorder: AudioRecorder
    let onDismiss: () -> Void
    let onSpeakToggle: (ChatBoxBiz) -> Void
    
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
            .background(DesignSystem.Colors.background)
            
            // Input bar overlay
            VStack {
                Spacer()
                InputBarView(recorder: recorder)
                    .background(
                        Rectangle()
                            .fill(DesignSystem.Colors.background.opacity(0))
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
    let onSpeakToggle: (ChatBoxBiz) -> Void
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 12) {
                    ForEach(Array(model.boxes.enumerated()), id: \.element.id) { index, box in
                        ChatBoxView(
                            box: model.boxes[index],
                            recorder: recorder,
                            onSpeakToggle: onSpeakToggle
                        )
                        .id(model.boxes[index].id)
                    }
                }
                .padding()
                Color.clear
                    .frame(height: 180)
                    .id("bottomSpacer")
                .onChange(of: model.boxes) { newBoxes in
                    print("Messages updated in view: \(newBoxes.count)")
                    if let lastMessage = newBoxes.last {
                        withAnimation {
                            proxy.scrollTo("bottomSpacer", anchor: .bottom)
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


// 更新 LoadingView 组件
private struct LoadingView: View {
    @State private var isAnimating = false
    private let dotCount = 3
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxSmall) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(DesignSystem.Colors.textSecondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// 更新 MessageContentView 中的 loading 视图
private struct MessageContentView: View {
    @ObservedObject var box: ChatBoxBiz
    @ObservedObject var data: ChatMessageBiz2
    let recorder: AudioRecorder
    var onSpeakToggle: (ChatBoxBiz) -> Void

    var body: some View {
        VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                if box.isMe { Spacer() }
                
                if box.loading {
                    LoadingView()
                } else {
                    VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
                        Text(data.text)
                            .font(DesignSystem.Typography.bodyMedium)
                        // if !data.ok {
                        //     Text(data.text)
                        //         .font(DesignSystem.Typography.bodyMedium)
                        // } else {
                        //     FlowLayout(spacing: 0) { 
                        //         ForEach(data.nodes) { node in
                        //             TextNodeView(
                        //                 node: node, 
                        //                 color: box.isMe ? DesignSystem.Colors.background : DesignSystem.Colors.textPrimary,
                        //                 onTap: { node in
                        //                     print("node: \(node)")
                        //                 }
                        //             )
                        //         }
                        //     }
                        // }
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(box.isMe ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.Radius.large)
                }
                
                if !box.isMe { Spacer() }
            }
            .blur(radius: box.blurred ? 4 : 0)
            .animation(.easeInOut(duration: 0.2), value: box.blurred)

            if !box.loading && !box.isMe {
                BotMessageActions(
                    box: box,
                    onSpeakToggle: { box in
                        onSpeakToggle(box)
                    }
                )
            }
        }
    }
}

// 同样更新 AudioContentView 中的 loading 视图
private struct AudioContentView: View {
    @ObservedObject var box: ChatBoxBiz
    @ObservedObject var data: ChatAudioBiz
    let recorder: AudioRecorder
    var onSpeakToggle: (ChatBoxBiz) -> Void

    var body: some View {
        VStack(alignment: box.isMe ? .trailing : .leading, spacing: 8) {
            HStack {
                if box.isMe { Spacer() }
                
                if box.loading {
                    LoadingView()
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
            .blur(radius: box.blurred ? 4 : 0)
            .animation(.easeInOut(duration: 0.2), value: box.blurred)

            if box.isMe && data.url != nil {
                UserMessageActions(
                    recorder: recorder,
                    box: box
                )
            } else if !box.isMe {
                BotMessageActions(
                    box: box,
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
    @ObservedObject var box: ChatBoxBiz
    var recorder: AudioRecorder
    let onSpeakToggle: (ChatBoxBiz) -> Void
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
                if case let .error(data) = box.payload {
                    ErrorContentView(data: data)
                }
            } else if box.type == "audio" {
                if case let .audio(data) = box.payload {
                    AudioContentView(
                        box: box,
                        data: data,
                        recorder: recorder,
                        onSpeakToggle: onSpeakToggle
                    )
                }
            } else if box.type == "message" {
                if case let .message(data) = box.payload {
                    MessageContentView(box: box, data: data, recorder: recorder, onSpeakToggle: onSpeakToggle)
                }
            } else if box.type == "quiz" {
                if case let .puzzle(data) = box.payload {
                    QuizContentView(data: data)
                        .frame(maxWidth: .infinity)
                }
            } else if box.type == "tip" {
                if case let .tip(data) = box.payload {
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
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text("出错了")
                    .font(DesignSystem.Typography.headingSmall)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(data.error)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .fill(DesignSystem.Colors.error.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
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
                return DesignSystem.Colors.success.opacity(0.1)
            } else {
                return DesignSystem.Colors.error.opacity(0.1)
            }
        }
        return DesignSystem.Colors.background
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("评估")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text(data.title)
                    .font(DesignSystem.Typography.headingSmall)
            }
            
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.medium) {
                ForEach(data.options) { option in
                    Button(action: {
//                        handleOptionSelection(option)
                    }) {
                        HStack {
                            Text(option.text)
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            Spacer()
                            if data.isSelected(option: option) {
                                Image(systemName: data.isCorrect(option: option) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(data.isCorrect(option: option) ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            }
                        }
                        .padding(DesignSystem.Spacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .fill(getBackgroundColor(for: option))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .stroke(DesignSystem.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(data.isSelected(option: option) && !data.isCorrect(option: option))
                }
            }
            
            if data.attempts > 0 {
                HStack {
                    Image(systemName: "info.circle")
                    Text(data.attempts == 1 ? "第一次尝试" : "第 \(data.attempts) 次尝试")
                    if data.corrected {
                        Text("- 答对了！")
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.top, DesignSystem.Spacing.xxSmall)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.Radius.large)
    }
}


struct RecordButton: View {
    @ObservedObject var recorder: AudioRecorder
    @State private var scale: CGFloat = 1.0
    @State private var cancelHighlighted: Bool = false
    var isLoading: Bool = false
    
    var body: some View {
        ZStack(alignment: .center) {
            if recorder.isRecording {
                VStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(cancelHighlighted ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                        .animation(.easeInOut, value: cancelHighlighted)
                    
                    Text("松开发送，上滑取消")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(cancelHighlighted ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary)
                }
                .offset(y: -140)
            }
            
            ZStack {
                Circle()
                    .stroke(recorder.isRecording ? 
                           (cancelHighlighted ? DesignSystem.Colors.error : DesignSystem.Colors.success) : 
                           Color.clear, lineWidth: 4)
                    .frame(width: 128, height: 128)
                    .scaleEffect(scale)
                
                Circle()
                    .fill(recorder.isRecording ? 
                          (cancelHighlighted ? DesignSystem.Colors.error.opacity(0.2) : DesignSystem.Colors.success.opacity(0.2)) : 
                          DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 108, height: 108)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                                    .scaleEffect(1.8)
                            } else {
                                Image(systemName: recorder.isRecording ? "waveform" : "mic.circle.fill")
                                    .font(.system(size: 68))
                                    .foregroundColor(recorder.isRecording ? 
                                                   (cancelHighlighted ? DesignSystem.Colors.error : DesignSystem.Colors.success) : 
                                                   DesignSystem.Colors.primary)
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
            HStack(spacing: DesignSystem.Spacing.medium) {
                Button(action: {}) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(.system(size: 24))
                }
                .frame(width: 50, height: 50)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.background)
                }
                .frame(width: 50, height: 50)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, DesignSystem.Spacing.medium)
            
            RecordButton(recorder: recorder)
                .frame(maxWidth: .infinity)
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.background)
                }
                .frame(width: 50, height: 50)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, DesignSystem.Spacing.medium)
        }
        .frame(height: 180)
    }
}


private struct UserMessageActions: View {
    let recorder: AudioRecorder
    @ObservedObject var box: ChatBoxBiz

    func play() {
        if case let .audio(data) = box.payload {
            recorder.playAudio(url: data.url) {
                //
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if case let .audio(data) = box.payload {
                Button(action: {
                    play()
                }) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: box.playing ? "stop.circle.fill" : "play.circle.fill")
                            .frame(width: 16, height: 16)
                            .imageScale(.medium)
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text(box.playing ? "停止" : "回放")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxSmall)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, DesignSystem.Spacing.xxSmall)
    }
}

private struct BotMessageActions: View {
    @ObservedObject var box: ChatBoxBiz
    
    let onSpeakToggle: (ChatBoxBiz) -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Button(action: {
                box.blurred.toggle()
            }) {
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Image(systemName: box.blurred ? "eye.slash.fill" : "eye.fill")
                        .frame(width: 16, height: 16)
                        .imageScale(.medium)
                    Text(box.blurred ? "显示" : "隐藏")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.vertical, DesignSystem.Spacing.xxSmall)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.textSecondary.opacity(0.1))
                .cornerRadius(DesignSystem.Radius.medium)
            }
            
            Button(action: {
                onSpeakToggle(box)
            }) {
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Image(systemName: box.speaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .frame(width: 16, height: 16)
                        .imageScale(.medium)
                    Text(box.speaking ? "停止" : "朗读")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.vertical, DesignSystem.Spacing.xxSmall)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.textSecondary.opacity(0.1))
                .cornerRadius(DesignSystem.Radius.medium)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xxSmall)
        .padding(.top, DesignSystem.Spacing.xxSmall)
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
