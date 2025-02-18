//
//  ContentView.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI
import AVFoundation

// 聊天消息模型
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isMe: Bool
    let timestamp: Date
    var nodes: [MsgTextNode]?
}

// 聊天会话模型
struct ChatSession: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let lastMessage: String
    let lastMessageTime: Date
    var unreadCount: Int
}

// 在 ChatSession struct 后添加以下模型
struct Season: Codable, Identifiable {
    let id: String
    let name: String
    let cover: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cover = "poster_path"
    }
}
struct ListResponseWithCursor<T: Codable>: Codable {
    let list: [T]
    let marker: String
    let pageSize: Int
    let total: Int
    enum CodingKeys: String, CodingKey {
        case list
        case marker = "next_marker"
        case pageSize = "page_size"
        case total
    }
}

struct BizResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T
}

struct FetchParams: Codable {
    let page: Int
    let pageSize: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case page
        case pageSize = "page_size"
        case name
    }
}

struct ContentView: View {
    @State private var chatSessions: [ChatSession] = [
        ChatSession(name: "张三", avatar: "person.circle.fill", lastMessage: "今天天气真不错", lastMessageTime: Date(), unreadCount: 2),
        ChatSession(name: "李四", avatar: "person.circle.fill", lastMessage: "下班一起吃饭吗？", lastMessageTime: Date(), unreadCount: 0),
        ChatSession(name: "王五", avatar: "person.circle.fill", lastMessage: "项目进展如何？", lastMessageTime: Date(), unreadCount: 1)
    ]
    
    @State private var seasons: [Season] = []
    
    func loadSeasons() {
        let hostname = "https://media.funzm.com"
        let endpoint = "/api/v2/wechat/season/list"
        let token = "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..hygHZsl86_hlWWsa.BRdG-tcb2YWwx3O9GSpD9AoEnyWi-NVMBVVlrU7rAsOA-pgc3MsbJeiym-h51yZiHCJznyewuW0dDnKyxypgPFDEnX2M20sotUbLEyapUBISA2YRQt0.ZFIfKHxLJpNBALOuXFU6PQ"
        
        let params = FetchParams(page: 1, pageSize: 20, name: "")
        
        guard let url = URL(string: hostname + endpoint) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("2.3.0", forHTTPHeaderField: "client-version")
        
        do {
            request.httpBody = try JSONEncoder().encode(params)
        } catch {
            print("Error encoding params: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
        //    dump(data) 
        //    dump(response)
        if let jsonString = String(data: data, encoding: .utf8) {
    print("收到的 JSON 数据：")
    print(jsonString)
}
            do {
                let response = try JSONDecoder().decode(BizResponse<ListResponseWithCursor<Season>>.self, from: data)
                dump(response)
                DispatchQueue.main.async {
                    self.seasons = response.data.list
                }
            } catch {
                print("Error decoding response: \(error)")
            }
        }.resume()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 新增的选择按钮
                Button(action: {
                    // 按钮点击事件处理
                }) {
                    HStack {
                        Text("🤖")
                            .font(.title2)
                        Text("请选择")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding(.vertical, 12)
                
                // 原有的 List 视图
                List(chatSessions) { session in
                    NavigationLink(destination: ChatDetailView(chatSession: session)) {
                        ChatRowView(chatSession: session)
                    }
                }
            }
            .navigationTitle("微信")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .onAppear {
            // loadSeasons()
        }
    }
}

// 聊天列表行视图
struct ChatRowView: View {
    let chatSession: ChatSession
    
    var body: some View {
        HStack {
            Image(systemName: chatSession.avatar)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(chatSession.name)
                        .font(.headline)
                    Spacer()
                    Text(formatDate(chatSession.lastMessageTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(chatSession.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Spacer()
                    if chatSession.unreadCount > 0 {
                        Text("\(chatSession.unreadCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 聊天详情页面
struct ChatDetailView: View {
    let chatSession: ChatSession
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(content: "你好！", isMe: false, timestamp: Date().addingTimeInterval(-3600)),
        ChatMessage(content: "最近怎么样？", isMe: true, timestamp: Date().addingTimeInterval(-1800)),
        ChatMessage(content: "一切都好", isMe: false, timestamp: Date())
    ]
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                .padding()
            }
            
            // 录音状态显示
            if isRecording {
                HStack {
                    Text("松开发送，上滑取消")
                        .foregroundColor(.gray)
                    Spacer()
                    if let startTime = recordingStartTime {
                        Text(formatDuration(from: startTime))
                            .foregroundColor(.gray)
                    }
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
                
                // 大的居中录音按钮
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
                            Image(systemName: isRecording ? "waveform" : "mic.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(isRecording ? .red : .blue)
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
                                // 上滑时显示取消提示
                                if value.translation.height < -50 {
                                    // TODO: 显示取消提示
                                }
                            }
                            .onEnded { value in
                                if value.translation.height < -50 {
                                    cancelRecording()
                                } else {
                                    stopRecording()
                                }
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
        }
        .navigationTitle(chatSession.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func startRecording() {
        isRecording = true
        recordingStartTime = Date()
        // 开始录音动画
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
            scale = 1.2
        }
        // TODO: 实现录音开始逻辑
    }
    
    private func stopRecording() {
        isRecording = false
        recordingStartTime = nil
        scale = 1.0
        // TODO: 实现录音结束并发送逻辑
    }
    
    private func cancelRecording() {
        isRecording = false
        recordingStartTime = nil
        scale = 1.0
        // TODO: 实现取消录音逻辑
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
}

struct TextError: Codable {
    let type: String
    let reason: String
    let correction: String
}

struct MsgTextNode: Codable, Identifiable {
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

// 添加自定义 Tooltip 视图
private struct TooltipView: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 提示内容
            Text(text)
                .font(.system(size: 14))
                .padding(8)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(4)
            
            // 箭头
            Triangle()
                .fill(Color(UIColor.systemBackground))
                .frame(width: 10, height: 5)
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
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
            .overlay(
                Group {
                    if isShowingTooltip, let error = node.error {
                        TooltipView(text: error.reason)
                            .offset(y: 25)
                    }
                }
            )
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
            // Display nodes in a single line using HStack
            HStack(spacing: 0) {
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

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var isShowingActions = false
    @State private var isShowingTranslation = false
    @State private var translatedText: String = ""
    let synthesizer = AVSpeechSynthesizer()
    
    var nodes: [MsgTextNode] {
        [MsgTextNode(id: 1, 
                     text: "There ", 
                     type: "text",
                     error: nil),
        MsgTextNode(id: 2, 
                     text: "are", 
                     type: "text",
                     error: TextError(type: "error",
                                    reason: "拼写错误",
                                    correction: "正确拼写")),
        MsgTextNode(id: 3, 
                     text: " a mistake in the sentence.", 
                     type: "text",
                     error: nil)
        ]
    }
    
    var body: some View {
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
                .background(message.isMe ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(16)
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
                
                ErrorIndicatorView(node: nodes.first)
            }
            
            if !message.isMe { Spacer() }
        }
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

#Preview {
    ContentView()
}
