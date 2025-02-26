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
import CoreData


class ContentViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var store: ChatStore
    @Published var config: Config
    @Published var showingChatConfig = false
    @Published var showingCalendar = false
    @Published var sessions: [ChatSessionBiz] = []
    @ObservedObject var capsuleVM = CapsuleButtonViewModel()

    init(store: ChatStore, config: Config) {
        self.store = store
        self.config = config
        // 在初始化时就获取数据
        Task {
            await MainActor.run {
                fetchSessions()
            }
        }
    }

    func fetchSessions() {
        let ctx = store.container.viewContext
        let request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
        request.sortDescriptors = [NSSortDescriptor(key: "updated_at", ascending: false)]
        request.fetchBatchSize = 20

        do {
            let fetchedSessions = try ctx.fetch(request)
            var result: [ChatSessionBiz] = []

            for session in fetchedSessions {
                let biz = ChatSessionBiz.from(session, in: store)

                let request = NSFetchRequest<ChatBox>(entityName: "ChatBox")
                request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id])
                request.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false)]
                request.fetchBatchSize = 1
                
                if let boxes = try? ctx.fetch(request) {
                    let boxes2: [ChatBoxBiz] = boxes.map {
                        let b = ChatBoxBiz.from($0, store: store)
                        b.load(session: biz, config: self.config)
                        return b
                    }
                    biz.setBoxes(boxes: boxes2)
                }
                
                result.append(biz)
            }

            DispatchQueue.main.async {
                if !result.isEmpty {
                    withAnimation {
                        self.sessions = result
                    }
                }
            }
        } catch {
            print("[Sessions] Error fetching sessions: \(error)")
        }
    }

    func pushChatDetailView(sessionId: UUID) {
        path.append(Route.ChatDetailView(sessionId: sessionId))
    }

}

struct ContentView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var selectedTab = 0  // 添加状态变量来跟踪选中的标签页
    @State private var isLoading = false // 添加加载状态
    @StateObject var model: ContentViewModel  // 改用 @StateObject

    init(model: ContentViewModel) {
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationStack(path: $model.path) {
            ZStack {
                TabView(selection: $selectedTab) {
                    // 聊天标签页
                    ChatListView(model: model)
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
                    
                    RoleListPage(path: $model.path, config: model.config)
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
                    // 设置 TabView 的背景为毛玻璃效果
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground() // 使用默认毛玻璃效果背景
                    
                    // 自定义背景色调
                    appearance.backgroundColor = .clear // 清除背景色以显示毛玻璃效果
                    appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial) // 添加毛玻璃效果
                    
                    // 应用外观设置
                    UITabBar.appearance().standardAppearance = appearance
                    if #available(iOS 15.0, *) {
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
                
                // 修改胶囊按钮部分
                VStack {
                    Spacer()
                    if model.capsuleVM.isVisible {
                        CapsuleButton(
                            text: model.capsuleVM.buttonText,
                            icon: model.capsuleVM.buttonIcon
                        ) {
                            print("Capsule button tapped")
                            model.capsuleVM.toggleVisibility()
                        }
                        .padding(.bottom, UIScreen.main.bounds.height / 6)
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.capsuleVM.isVisible)
            }
            .sheet(isPresented: $model.showingCalendar) {
                CalendarPopupView(isPresented: $model.showingCalendar)
                    .presentationDetents([.medium])  // 只允许中等高度，移除 .large 选项
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                    case .ChatDetailView(let sessionId):
                        ChatDetailView(sessionId: sessionId, config: model.config).environmentObject(model.config)
                    case .VocabularyView(let filepath):
                        Vocabulary(filepath: filepath, path: model.path, store: model.store).environmentObject(model.store)
                    case .RoleDetailView(let roleId):
                        RoleDetailView(roleId: roleId, path: model.path, config: model.config).environmentObject(model.config)
                }
            }
            .environmentObject(model.store)
        }.environmentObject(model.store)
    }
}

struct ChatListView: View {
    @ObservedObject var model: ContentViewModel
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部按钮组 - 现在固定在顶部
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ChatButton(icon: "🤖", text: "想法", onTap: {
                            model.showingChatConfig = true
                        })
                        ChatButton(icon: "📚", text: "单词", onTap: {
                            model.capsuleVM.toggleVisibility()
                        })
                        ChatButton(icon: "📅", text: "日历", onTap: {
                            withAnimation {
                                model.showingCalendar = true
                            }
                        })
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                } else if model.sessions.isEmpty {
                    EmptyStateView()
                } else {
                    ForEach(Array(model.sessions.enumerated()), id: \.element.id) { index, session in
                        ChatSessionCardView(session: session, model: model)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color(UIColor.systemBackground))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    ChatSessionBiz.delete(session: session, in: model.store)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        // 只有不是最后一个元素时才添加分隔线
                        .listRowSeparator(index == model.sessions.count - 1 ? .hidden : .visible)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// 将空状态视图抽取为单独的组件
struct EmptyStateView: View {
    var body: some View {
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
                    .font(DesignSystem.Typography.bodyMedium)
                Text(text)
                    .font(DesignSystem.Typography.bodyMedium)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xLarge)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
    let session: ChatSessionBiz
    let model: ContentViewModel
    
    var body: some View {
        Button(action: {
            model.pushChatDetailView(sessionId: session.id)
        }) {
            HStack(alignment: .top, spacing: 16) {
                // 头像部分
                ZStack(alignment: .topTrailing) {
                    Avatar(uri: session.avatar_uri, size: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if session.unreadCount > 0 {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .offset(x: 3, y: -3)
                    }
                }
                
                // 内容部分
                VStack(alignment: .leading, spacing: 8) {  // 增加间距从 6 到 8
                    HStack {
                        Text(session.title)
                            .font(.system(size: 17, weight: .semibold))  // 增加字体大小并加粗
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatDate(session.updated_at))
                            .font(.system(size: 14))  // 增加时间字体大小
                            .foregroundColor(.gray)
                    }
                    if session.boxes.count > 0 {
                        ChatMsgPreview(box: session.boxes[0])
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
                case "puzzle":
                    if case .puzzle = box.payload {
                        Text("[puzzle]")
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
