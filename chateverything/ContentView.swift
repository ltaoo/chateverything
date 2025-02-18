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
    @State private var selectedTab = 0  // 添加状态变量来跟踪选中的标签页
    
    @EnvironmentObject private var navigationManager: NavigationStateManager
    
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
        TabView(selection: $selectedTab) {
            // 聊天标签页
            NavigationStack {
                VStack(spacing: 0) {
                    // 原有的 List 视图
                    List(chatSessions) { session in
                        Button {
                            let chatDetailView = ChatDetailView(
                                chatSession: session,
                                model: LLMService(model: LanguageModel(
                                    providerName: "deepseek",
                                    id: "deepseek-chat",
                                    name: "deepseek-chat",
                                    apiKey: "sk-292831353cda4d1c9f59984067f24379",
                                    apiProxyAddress: "https://api.deepseek.com/chat/completions",
                                    responseHandler: { data in
                                        let decoder = JSONDecoder()
                                        let response = try decoder.decode(DeepseekChatResponse.self, from: data)
                                        return response.choices[0].message.content
                                    }
                                ), prompt: prompt)
                            )
                            withAnimation(.easeInOut(duration: 0.3)) {
                                navigationManager.navigateToChatDetail(view: chatDetailView)
                            }
                        } label: {
                            ChatRowView(chatSession: session)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            // 移动到右上角的选择按钮
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("聊天")
            }
            .tag(0)
            
            // 探索标签页
            NavigationStack {
                Text("探索页面")
                    .navigationTitle("探索")
            }
            .tabItem {
                Image(systemName: "safari.fill")
                Text("探索")
            }
            .tag(1)
            
            // 发现标签页
            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("发现")
            }
            .tag(2)
            
            // 我的标签页
            NavigationStack {
               MineView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("我的")
            }
            .tag(3)
        }
        .onAppear {
            // loadSeasons()
        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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

#Preview {
    ContentView()
}
