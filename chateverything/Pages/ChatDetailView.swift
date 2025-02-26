import SwiftUI
import Foundation
import AVFoundation
import Speech
import Combine
struct DictionaryView: UIViewControllerRepresentable {
    let word: String
    
    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        return UIReferenceLibraryViewController(term: word)
    }
    
    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {
    }
}


class ChatDetailViewModel: ObservableObject {
    let config: Config
    let store: ChatStore
    @Published var session: ChatSessionBiz
    @Published var boxes: [ChatBoxBiz] = []
    
    private var cancellables = Set<AnyCancellable>()

    @Published var loading = true
    @Published var disabled = true
    @Published var roleDetailVisible = false
    @Published var promptPopoverVisible = false
    @Published var permissionAlertVisible = false
    @Published var error: String?

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
        
        self.session.$boxes
            .sink { [weak self] newBoxes in
                // print("newBoxes: \(newBoxes.count)")
                DispatchQueue.main.async {
                    self?.boxes = newBoxes
                }
            }
            .store(in: &cancellables)
    }
    func load() {
        self.session.load(id: self.session.id, config: self.config)
        for member in self.session.members {
            if let role = member.role {
                if role.disabled {
                    continue
                }
                if role.id == config.me.id {
                    continue
                }
                let boxes: [ChatBoxBiz] = self.session.getBoxesForMember(roleId: role.id, config: config)
                let llmMessages: [LLMServiceMessage?] = boxes.map {
                    print("box: \($0.type) \(String(describing: $0.payload))")
                    guard let payload = $0.payload else {
                        return nil
                    }
                    if $0.type == "message" {
                        if case let .message(message) = $0.payload {
                            return LLMServiceMessage(role: $0.sender_id == config.me.id ? "user" : "assistant", content: message.text)
                        } else {
                            print("box: type is message, but payload is not message")
                            // return LLMServiceMessage(role: "assistant", content: "")
                            return nil
                        }
                    } else if $0.type == "audio" {
                        if case let .audio(audio) = $0.payload {
                            return LLMServiceMessage(role: $0.sender_id == config.me.id ? "user" : "assistant", content: audio.text)
                        } else {
                            print("box: type is audio, but payload is not audio")
                            // return LLMServiceMessage(role: "assistant", content: "")
                            return nil
                        }
                    }
                    print("box: type is \($0.type), but payload is not message or audio")
                    // return LLMServiceMessage(role: "assistant", content: "")
                    return nil
                }
                let msgs = llmMessages.compactMap { $0 }
                print("llmMessages: \(msgs.count)")
                role.setMessages(messages: msgs)
            }
        }
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
    func sendTextMessage(text: String) {
        let userMessage = ChatBoxBiz(
            id: UUID(),
            type: "message",
            created_at: Date(),
            isMe: true,
            payload_id: UUID(),
            session_id: self.session.id,
            sender_id: config.me.id,
            payload: ChatPayload.message(
                ChatMessageBiz2(
                    text: text,
                    nodes: []
                )
            ),
            loading: false,
            blurred: false
        )
        self.session.appendBox(box: userMessage)

        for member in self.session.members {
            if let role = member.role {
                if role.disabled {
                    continue
                }
                if role.id == config.me.id {
                    continue
                }
                role.response(text: text, session: self.session, config: config)
            }
        }
    }
    func sendAudioMessage(text: String, url: URL, duration: TimeInterval) {
        let userMessage = ChatBoxBiz(
            id: UUID(),
            type: "audio",
            created_at: Date(),
            isMe: true,
            payload_id: UUID(),
            session_id: self.session.id,
            sender_id: config.me.id,
            payload: ChatPayload.audio(
                ChatAudioBiz(
                    text: text,
                    nodes: [],
                    url: url,
                    duration: duration
                )
            ),
            loading: false,
            blurred: false
        )
        self.session.appendBox(box: userMessage)

        for member in self.session.members {
            if let role = member.role {
                if role.disabled {
                    continue
                }
                if role.id == config.me.id {
                    continue
                }
                role.response(text: text, session: self.session, config: config)
            }
        }
    }
    
    func appendMessage(box: ChatBoxBiz) {
        print("Appending message to session")
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.session.appendBox(box: box)
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

    @State private var toastMessage: String?
    
    init(sessionId: UUID, config: Config) {
        self.sessionId = sessionId
        self.config = config
        self.store = config.store
        let model = ChatDetailViewModel(id: sessionId, config: config, store: config.store)
        _model = StateObject(wrappedValue: model)
        let recorder = AudioRecorder()
        _recorder = StateObject(wrappedValue: recorder)
       
    }

    // 将回调设置移到 onAppear
    private func setupRecorderCallbacks() {
        // 设置录音完成的回调
        self.recorder.onCompleted = { url in
            print("complete audio recording, the url: \(url)")
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false)
            } catch {
                print("error: \(error)")
            }
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
        self.model.sendAudioMessage(text: recognizedText, url: audioURL, duration: duration)
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
            config: config,
            recorder: recorder,
            onDismiss: { dismiss() }
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
            DictionaryView(word: "present")
        }
        .onAppear {
            setupRecorderCallbacks()
            model.load()

            for member in model.session.members {
                if let role = member.role {
                    role.start(session: model.session, config: config)
                }
            }
        }
        .onDisappear {
            self.recorder.cleanup()
        }
        .onReceive(model.session.$boxes) { newBoxes in
            model.boxes = newBoxes
        }
    }
}

// 拆分出主要内容视图
private struct ChatDetailContentView: View {
    let model: ChatDetailViewModel
    let config: Config
    let recorder: AudioRecorder
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                ChatMessageList(
                    model: model,
                    recorder: recorder
                )
            }
            .background(DesignSystem.Colors.background)
            
            VStack {
                Spacer()
                InputBarView(config: config, model: model, recorder: recorder)
            }
        }
    }
}

// 拆分出消息列表视图
private struct ChatMessageList: View {
    @ObservedObject var model: ChatDetailViewModel
    let recorder: AudioRecorder
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 12) {
                    ForEach(Array(model.boxes.enumerated()), id: \.element.id) { index, box in
                        ChatBoxView(
                            box: model.boxes[index],
                            recorder: recorder
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
        let radius: CGFloat = 2 // 圆角半径
        
        // 计算三角形的三个点
        let tip = CGPoint(x: rect.minX, y: rect.midY)
        let top = CGPoint(x: rect.maxX, y: rect.minY)
        let bottom = CGPoint(x: rect.maxX, y: rect.maxY)
        
        // 绘制带圆角的路径
        path.move(to: tip)
        path.addQuadCurve(to: top, control: CGPoint(x: tip.x + radius, y: top.y + radius))
        path.addLine(to: bottom)
        path.addQuadCurve(to: tip, control: CGPoint(x: tip.x + radius, y: bottom.y - radius))
        
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

    var body: some View {
        VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
            HStack {
                if box.isMe { Spacer() }
                
                if box.loading {
                    LoadingView()
                } else {
                    HStack(spacing: 0) {
                        if !box.isMe {
                            // 左侧小矩形
                            Rectangle()
                                .fill(DesignSystem.Colors.secondaryBackground)
                                .frame(width: 16, height: 16)
                                .cornerRadius(DesignSystem.Radius.small)
                                .rotationEffect(.degrees(45))
                                .offset(x: 12)
                        }
                        
                        VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            Text(data.text)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(box.isMe ? .white : DesignSystem.Colors.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.medium)
                        .background(box.isMe ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.Radius.large)
                        
                        if box.isMe {
                            // 右侧小矩形
                            Rectangle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 16, height: 16)
                                .cornerRadius(DesignSystem.Radius.small)
                                .rotationEffect(.degrees(45))
                                .offset(x: -12)
                        }
                    }
                }
                
                if !box.isMe { Spacer() }
            }
            .blur(radius: box.blurred ? 4 : 0)
            .animation(.easeInOut(duration: 0.2), value: box.blurred)

            if !box.loading && !box.isMe {
                BotMessageActions(
                    box: box
                )
                .offset(x: 12)
            }
        }
    }
}

// 更新 AudioContentView 中的 loading 视图
private struct AudioContentView: View {
    @ObservedObject var box: ChatBoxBiz
    @ObservedObject var data: ChatAudioBiz
    let recorder: AudioRecorder

    var body: some View {
        VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
            HStack {
                if box.isMe { Spacer() }
                
                if box.loading {
                    LoadingView()
                } else {
                    HStack(spacing: 0) {
                        if !box.isMe {
                            // 左侧小矩形
                            Rectangle()
                                .fill(DesignSystem.Colors.secondaryBackground)
                                .frame(width: 16, height: 16)
                                .cornerRadius(DesignSystem.Radius.small)
                                .rotationEffect(.degrees(45))
                                .offset(x: 12)
                        }
                        
                        VStack(alignment: box.isMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            Text(data.text)
                                .foregroundColor(box.isMe ? .white : DesignSystem.Colors.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.medium)
                        .background(box.isMe ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.Radius.large)
                        
                        if box.isMe {
                            // 右侧小矩形
                            Rectangle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 16, height: 16)
                                .cornerRadius(DesignSystem.Radius.small)
                                .rotationEffect(.degrees(45))
                                .offset(x: -12)
                        }
                    }
                    .zIndex(1) // 确保小矩形显示在正确的层级
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
                .offset(x: -12)
            } else if !box.isMe {
                BotMessageActions(
                    box: box
                )
                .offset(x: -12)
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

struct TipTextContentView: View {
    let data: ChatTipTextBiz

    var body: some View {
        Text(data.content)
            .font(DesignSystem.Typography.bodySmall)
            .multilineTextAlignment(.center)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(DesignSystem.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// 在 ChatBoxView 的 body 中更新条件分支
struct ChatBoxView: View {
    @ObservedObject var box: ChatBoxBiz
    var recorder: AudioRecorder
    @State private var isShowingActions = false

    init(box: ChatBoxBiz, recorder: AudioRecorder) {
        self.box = box
        self.recorder = recorder
        print("box \(box.type)")
    }

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
                        recorder: recorder
                    )
                }
            } else if box.type == "message" {
                if case let .message(data) = box.payload {
                    MessageContentView(box: box, data: data, recorder: recorder)
                }
            } else if box.type == "puzzle" {
                if case let .puzzle(data) = box.payload {
                    PuzzleContentView(data: data)
                        .frame(maxWidth: .infinity)
                }
            } else if box.type == "tip" {
                if case let .tip(data) = box.payload {
                    TipContentView(data: data)
                }
            } else if box.type == "tipText" {
                if case let .tipText(data) = box.payload {
                    TipTextContentView(data: data)
                }
            }
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

// 更新 PuzzleContentView 组件
struct PuzzleContentView: View {
    @ObservedObject var data: ChatPuzzleBiz

    @State private var selectedOption: UUID?
    @State private var showResult: Bool = false
    @State private var attempts: Int = 0
    
    var columns: [GridItem] {
        return data.options.count > 2 ? [
            GridItem(.flexible())
        ] : [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
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
                Text(data.title)
                    .font(DesignSystem.Typography.headingSmall)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.small) {
                ForEach(data.options) { option in
                    Button(action: {
                        data.selectOption(option: option)
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
            
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.Radius.large)
    }
}


struct RecordButton: View {
    @ObservedObject var recorder: AudioRecorder
    @State private var dragOffset: CGFloat = 0
    @State private var cancelHighlighted = false
    @State private var insertHighlighted = false

    var color: Color {
        if cancelHighlighted {
            return Color.red.opacity(0.2)
        } else if insertHighlighted {
            return Color.green.opacity(0.2)
        } else if recorder.isRecording {
            return Color.green.opacity(0.2)
        } else {
            return Color.blue.opacity(0.1)
        }
    }
    
    var color2: Color {
        if cancelHighlighted {
            return Color.red
        } else if insertHighlighted {
            return Color.green
        } else if recorder.isRecording {
            return Color.green
        } else {
            return Color.blue
        }
    }
    
    var text: String {
        if cancelHighlighted {
            return "取消"
        } else if insertHighlighted {
            return "发送"
        } else if recorder.isRecording {
            return "松开发送"
        } else {
            return "按住说话"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(color)
                    .animation(.easeInOut(duration: 0.2), value: color)
                    .overlay(
                        HStack(spacing: 8) {
                            Image(systemName: recorder.isRecording ? "waveform" : "mic")
                                .foregroundColor(color2)
                                .animation(.easeInOut(duration: 0.2), value: color2)
                            Text(text)
                                .font(.system(size: 15))
                                .foregroundColor(color2)
                                .animation(.easeInOut(duration: 0.2), value: color2)
                        }
                    )
                    .cornerRadius(8)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.2)
                            .onEnded { _ in
                                recorder.startRecording()
                            }
                            .simultaneously(with: DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    print("value \(value.translation.width) \(value.translation.height)")
                                    // Remove dragOffset update to prevent button movement
                                    cancelHighlighted = value.translation.width < -100 && value.translation.height < -100
                                    insertHighlighted = value.translation.width > 50
                                }
                                .onEnded { value in
                                    if value.translation.width < -100 && value.translation.height < -100 {
                                        recorder.cancelRecording()
                                    } else if value.translation.width > 50 {
                                        recorder.stopRecording() { url in
                                            print("Recording completed for text insertion")
                                        }
                                    } else {
                                        recorder.stopRecording() { url in
                                            print("Recording completed for sending")
                                        }
                                    }
                                    cancelHighlighted = false
                                    insertHighlighted = false
                                })
                    )


                // 录音状态提示
                // 使用 opacity 而不是条件渲染来避免布局变化
                if recorder.isRecording {
                    HStack(spacing: 0) {
                        // 左侧取消提示
                        VStack(spacing: 0) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 48))
                            Text("取消")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(cancelHighlighted ? .red : .gray)
                        .animation(.easeInOut(duration: 0.2), value: cancelHighlighted)

                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    .opacity(recorder.isRecording ? 1 : 0)
                    .frame(height: 46) // 固定 RecordButton 的高度
                    .offset(y: -160)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 46) // 固定 RecordButton 的高度
    }
}

// 更新 InputBarView 组件
struct InputBarView: View {
    let config: Config
    let model: ChatDetailViewModel
    @ObservedObject var recorder: AudioRecorder
    @State private var isKeyboardMode = false
    @State private var inputText = ""
    
    var body: some View {
        ZStack {
            // Background color
            Color(uiColor: .systemBackground)
                .edgesIgnoringSafeArea(.bottom)
            
            HStack(alignment: .center, spacing: 8) { // Ensure .center alignment
                Spacer()
                
                // Middle area - vertically center the content
                HStack(alignment: .center) { // Add HStack with .center alignment
                    if isKeyboardMode {
                        TextField("说点什么...", text: $inputText)
                            .submitLabel(.send)
                            .onSubmit {
                                if !inputText.isEmpty {
                                    model.sendTextMessage(text: inputText)
                                    inputText = ""
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(8)
                    } else {
                        RecordButton(recorder: recorder)
                    }
                }
                
                // Right keyboard/voice toggle button
                HStack(alignment: .center) {
                    Button(action: {
                        isKeyboardMode.toggle()
                    }) {
                    Image(systemName: isKeyboardMode ? "mic" : "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    }
                }
                .frame(width: 44, height: 44) // 固定尺寸
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(height: 70)
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
    
    func handleSpeak() {
//        if let tts = box.role.tts {
//            if let text = box.payload?.text {
//                tts.speak(text)
//            }
//        }
    }
    
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
                self.handleSpeak()
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
