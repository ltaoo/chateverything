//
//  ContentView.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI

// 聊天消息模型
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isMe: Bool
    let timestamp: Date
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

struct ContentView: View {
    @State private var chatSessions: [ChatSession] = [
        ChatSession(name: "张三", avatar: "person.circle.fill", lastMessage: "今天天气真不错", lastMessageTime: Date(), unreadCount: 2),
        ChatSession(name: "李四", avatar: "person.circle.fill", lastMessage: "下班一起吃饭吗？", lastMessageTime: Date(), unreadCount: 0),
        ChatSession(name: "王五", avatar: "person.circle.fill", lastMessage: "项目进展如何？", lastMessageTime: Date(), unreadCount: 1)
    ]
    
    var body: some View {
        NavigationStack {
            List(chatSessions) { session in
                NavigationLink(destination: ChatDetailView(chatSession: session)) {
                    ChatRowView(chatSession: session)
                }
            }
            .navigationTitle("微信")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
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
    @State private var isShowingHandwriting = false
    
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
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                }
                
                TextField("输入消息", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    isShowingHandwriting.toggle()
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 24))
                }
                
                Button(action: sendMessage) {
                    Text("发送")
                }
            }
            .padding()
        }
        .navigationTitle(chatSession.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingHandwriting) {
            HandwritingView { recognizedText in
                if !recognizedText.isEmpty {
                    messageText = recognizedText
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = ChatMessage(content: messageText, isMe: true, timestamp: Date())
        messages.append(newMessage)
        messageText = ""
    }
}

// 消息气泡视图
struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isMe {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isMe ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isMe ? .white : .black)
                .cornerRadius(16)
            
            if !message.isMe {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
