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
import LLM

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
    @EnvironmentObject var chatStore: ChatStore
    // @StateObject private var chatStore = ChatStore()
    @State private var selectedTab = 0  // 添加状态变量来跟踪选中的标签页
    
    @State private var showingChatConfig = false
    @State private var isLoading = false // 添加加载状态
    
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
        TabView(selection: $selectedTab) {
            // 聊天标签页
            NavigationView {
                ChatListView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ChatButton(onTap: {
                                showingChatConfig = true
                            })
                        }
                    }
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("聊天")
            }
            .tag(0)
            
            // 探索标签页
            NavigationView {
                Text("探索功能开发中...")
            }
            .tabItem {
                Image(systemName: "safari.fill")
                Text("探索")
            }
            .tag(1)
            
            // 发现标签页
            NavigationView {
                Text("发现功能开发中...")
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("发现")
            }
            .tag(2)
            
            // 我的标签页
            NavigationView {
                Text("我的功能开发中...")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("我的")
            }
            .tag(3)
        }
        .onAppear {
            loadChatSessions()
        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showingChatConfig) {
            RoleSelectionView()
        }
    }
    
    private func loadChatSessions() {
        isLoading = true
        
        // 使用异步操作来模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chatStore.loadInitialSessions(limit: 20)
            isLoading = false
        }
    }
}

struct ChatButton: View {
    var onTap: () -> Void  // 添加点击回调属性
    
    var body: some View {
        HStack {
            Button(action: onTap) {  // 使用传入的 onTap 回调
                HStack {
                    Text("🤖")
                        .font(.title2)
                    Text("新对话")
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
}

// 聊天列表行视图
struct ChatRowView: View {
    let chatSession: ChatSessionBiz
    
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
                    // Text(chatSession.lastMessage)
                    //     .font(.subheadline)
                    //     .foregroundColor(.gray)
                    //     .lineLimit(1)
                    // Spacer()
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


// 添加 String 扩展来支持保留分隔符的分割
extension String {
    func split(includesSeparators: Bool, 
              whereSeparator isSeparator: (Character) -> Bool) -> [Substring] {
        var result: [Substring] = []
        var start = self.startIndex
        
        for i in self.indices {
            if isSeparator(self[i]) {
                if i > start {
                    result.append(self[start..<i])
                }
                if includesSeparators {
                    result.append(self[i...i])
                }
                start = self.index(after: i)
            }
        }
        
        if start < self.endIndex {
            result.append(self[start..<self.endIndex])
        }
        
        return result
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
    @EnvironmentObject var chatStore: ChatStore
    @State private var isLoading = false
    
    var body: some View {
        VStack {  // 将 Group 改为 VStack
            if isLoading {
                ProgressView()
            } else if chatStore.sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "message")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("暂无聊天记录")
                        .foregroundColor(.gray)
                }
            } else {
                List(chatStore.sessions) { session in
                    ChatRowView(chatSession: session)
                }
            }
        }
        .navigationTitle("聊天")
    }
}

#Preview {
    ContentView()
}
