//
//  ContentView.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI
import AVFoundation
import Speech
import Foundation
import UIKit
import Network

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

// 添加 NavigationStateManager 类
// class NavigationStateManager: ObservableObject {
//     @Published var path = NavigationPath()
// }

struct ContentView: View {
    @EnvironmentObject var store: ChatStore
    @EnvironmentObject var config: Config
    @EnvironmentObject var networkManager: NetworkManager
    @StateObject private var capsuleVM = CapsuleButtonViewModel()
    @State private var selectedTab = 0  // 添加状态变量来跟踪选中的标签页
    @State private var path = NavigationPath()
    
    @State private var showingChatConfig = false
    @State private var isLoading = false // 添加加载状态
    @State private var showingCalendar = false
    
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
                // DispatchQueue.main.async {
                //     self.seasons = response.data.list
                // }
            } catch {
                print("Error decoding response: \(error)")
            }
        }.resume()
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                TabView(selection: $selectedTab) {
                    // 聊天标签页
                    ChatListView(capsuleVM: capsuleVM, path: $path, showingChatConfig: $showingChatConfig, showingCalendar: $showingCalendar)
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("聊天")
                        }
                        .tag(0)
                    
                    SceneView()
                    .tabItem {
                        Image(systemName: "safari.fill")
                        Text("探索")
                    }
                    .tag(1)
                    
                    RoleListPage(path: $path, config: self.config)
                    .tabItem {
                        Image(systemName: "sparkles")
                        Text("角色")
                    }
                    .tag(2)
                    
                    MineView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
                    .tag(3)
                }
                .onAppear {
                    // 设置 TabView 的背景颜色为浅灰色
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor.systemGray6
                    
                    UITabBar.appearance().standardAppearance = appearance
                    if #available(iOS 15.0, *) {
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
                
                // 修改胶囊按钮部分
                VStack {
                    Spacer()
                    if capsuleVM.isVisible {
                        CapsuleButton(
                            text: capsuleVM.buttonText,
                            icon: capsuleVM.buttonIcon
                        ) {
                            print("Capsule button tapped")
                            capsuleVM.toggleVisibility()
                        }
                        .padding(.bottom, UIScreen.main.bounds.height / 6)
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: capsuleVM.isVisible)
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarPopupView(isPresented: $showingCalendar)
                    .presentationDetents([.medium])  // 只允许中等高度，移除 .large 选项
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                    case .ChatDetailView(let sessionId):
                        ChatDetailView(sessionId: sessionId, config: self.config).environmentObject(self.config)
                    case .VocabularyView(let filepath):
                        Vocabulary(filepath: filepath, path: self.path, store: self.store).environmentObject(self.store)
                    case .RoleDetailView(let roleId):
                        RoleDetailView(roleId: roleId, path: self.path, config: self.config).environmentObject(self.config)
                }
            }
            .onAppear {
                store.fetchSessions()
            }
            .environmentObject(self.store)
        }.environmentObject(self.store)
    }
    
    private func loadChatSessions() {
        isLoading = true
        
        // 使用异步操作来模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            store.loadInitialSessions(limit: 20)
            isLoading = false
        }
    }
}

struct ChatButton: View {
    var icon: String
    var text: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 20))  // 增大表情符号
                Text(text)
                    .font(.system(size: 16, weight: .medium))  // 增大字体并加粗
                // Image(systemName: "chevron.down")
                //     .font(.system(size: 14))  // 增大箭头
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)  // 增加水平内边距
            .padding(.vertical, 10)    // 增加垂直内边距
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)  // 添加轻微阴影
            )
        }
        .buttonStyle(ScaleButtonStyle())  // 添加按压效果
    }
}

// 添加自定义按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// 聊天列表行视图
struct ChatSessionCardView: View {
    let chatSession: ChatSessionBiz
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // 头像部分
                ZStack(alignment: .topTrailing) {
                    Avatar(uri: chatSession.avatar_uri, size: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if chatSession.unreadCount > 0 {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .offset(x: 3, y: -3)
                    }
                }
                
                // 内容部分
                VStack(alignment: .leading, spacing: 8) {  // 增加间距从 6 到 8
                    HStack {
                        Text(chatSession.title)
                            .font(.system(size: 17, weight: .semibold))  // 增加字体大小并加粗
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatDate(chatSession.updated_at))
                            .font(.system(size: 14))  // 增加时间字体大小
                            .foregroundColor(.gray)
                    }
                    if chatSession.boxes.count > 0 {
                        ChatMsgPreview(box: chatSession.boxes[0])
                            .foregroundColor(.gray)
                            .font(.system(size: 15))  // 增加预览文字大小
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)  // 增加垂直内边距从 8 到 12
            .padding(.horizontal, 4)  // 添加水平内边距
            .contentShape(Rectangle())
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color(UIColor.systemGray6))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct ChatMsgPreview: View {
    let box: ChatBoxBiz?

    var body: some View {
        Group {
            if let box = box {
                switch box.type {
                case "error":
                    if case let .error(data) = box.payload {
                        Text("[error]\(data.error)")
                    }
                case "audio":
                    if case .audio = box.payload {
                        Text("[audio]")
                    }
                case "message":
                    if case let .message(data) = box.payload {
                        Text(data.text)
                    }
                case "quiz":
                    if case .puzzle = box.payload {
                        Text("[quiz]")
                    }
                case "tip":
                    if case let .tip(data) = box.payload {
                        Text("[tip]\(data.title)")
                    }
                default:
                    Text("未知消息类型: \(box.type)")
                }
            } else {
                Text("")
            }
        }
    }
}

// 确保 ChatDetailView 符合 Hashable 协议
// extension ChatDetailView: Hashable {
//     static func == (lhs: ChatDetailView, rhs: ChatDetailView) -> Bool {
//         lhs.chatSession.id == rhs.chatSession.id
//     }
    
//     func hash(into hasher: inout Hasher) {
//         hasher.combine(chatSession.id)
//     }
// }

// 新增 ChatListView 组件
struct ChatListView: View {
    @EnvironmentObject var store: ChatStore
    var capsuleVM: CapsuleButtonViewModel
    @Binding var path: NavigationPath
    @State private var isLoading = false
    @Binding var showingChatConfig: Bool
    @Binding var showingCalendar: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部按钮组 - 现在固定在顶部
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ChatButton(icon: "🤖", text: "想法", onTap: {
                            showingChatConfig = true
                        })
                        ChatButton(icon: "📚", text: "单词", onTap: {
                            capsuleVM.toggleVisibility()
                        })
                        ChatButton(icon: "📅", text: "日历", onTap: {
                            withAnimation {
                                showingCalendar = true
                            }
                        })
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                
                Divider()
                    .frame(height: 0.5)
                    .background(Color(.systemGray6))
                    .opacity(0.8)
            }
            
            // 将 ScrollView 和 LazyVStack 替换为 List
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                } else if store.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 100)
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无聊天记录")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(store.sessions.enumerated()), id: \.element.id) { index, session in
                        ChatSessionCardView(chatSession: session, onTap: {
                            path.append(Route.ChatDetailView(sessionId: session.id))
                        })
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color(UIColor.systemBackground))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
//                                    store.deleteSession(sessionId: session.id)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        // 只有不是最后一个元素时才添加分隔线
                        .listRowSeparator(index == store.sessions.count - 1 ? .hidden : .visible)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// 更新 CapsuleButton 视图
struct CapsuleButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(text)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
