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
    @EnvironmentObject var store: ChatStore
    // @StateObject private var store = ChatStore()
    @State private var selectedTab = 0  // 添加状态变量来跟踪选中的标签页
    @State private var path = NavigationPath()
    
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
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                // 聊天标签页
                ChatListView(path: $path, showingChatConfig: $showingChatConfig)
                   
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("聊天")
                    }
                    .tag(0)
                
                // 探索标签页
                    Text("探索功能开发中...")
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("探索")
                }
                .tag(1)
                
                // 发现标签页
                    Text("发现功能开发中...")
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("发现")
                }
                .tag(2)
                
                // 我的标签页
                    Text("我的功能开发中...")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
            }
            .sheet(isPresented: $showingChatConfig) {
                RoleSelectionView(path: $path, onCancel: {
                    showingChatConfig = false
                })
            }
            .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ChatButton(onTap: {
                                showingChatConfig = true
                            })
                        }
                    }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .ChatDetailView(let sessionId):
                    ChatDetailView(sessionId: sessionId, store: self.store).environmentObject(self.store)
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
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text("🤖")
                    .font(.system(size: 16))
                Text("新对话")
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}


// 聊天列表行视图
struct ChatRowView: View {
    let chatSession: ChatSessionBiz
    var onTap: () -> Void
    
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
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
    @Binding var path: NavigationPath
    @State private var isLoading = false
    @Binding var showingChatConfig: Bool
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if store.sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "message")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("暂无聊天记录")
                        .foregroundColor(.gray)
                }
            } else {
                List(store.sessions) { session in
                    ChatRowView(chatSession: session, onTap: {
                        path.append(Route.ChatDetailView(sessionId: session.id))
                    })
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
