//
//  chateverythingApp.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI
import CoreData
import Network

@main
struct ChatEverythingApp: App {
//    let persistenceController = PersistenceController.shared
    // let store: ChatStore
    let container = PersistenceController.container
    // @StateObject var store: ChatStore
    var store: ChatStore
    var config: Config
    @StateObject private var networkManager = NetworkManager()
    
    init() {
        // store = ChatStore(container: PersistenceController.container)
        store = ChatStore(container: container)
        config = Config(store: store)
        // _store = StateObject(wrappedValue: ChatStore(container: container))
        
        // let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // do {
        //     let existingUsers = try context.fetch(fetchRequest)
        //     if existingUsers.isEmpty {
               
        //     }
        // } catch {
        //     print("Error initializing user: \(error)")
        // }
                // guard let entity = NSEntityDescription.entity(forEntityName: "User", in: context) else {
                //     fatalError("Failed to initialize UserEntity")
                // }
                
                // let user = UserEntity(entity: entity, insertInto: context)
                // user.id = UUID()
                // user.name = "John Doe"
                // user.avatar = "https://example.com/avatar.png"
                // user.created_at = Date()
                
                // try context.save()
        // RoleEntity.createDefaultRoles(in: context)

                // guard let entity = NSEntityDescription.entity(forEntityName: "Role", in: context) else {
                //     fatalError("Failed to initialize UserEntity")
                // }
                // let role = Role(entity: entity, insertInto: context)
                // role.id = UUID()
                // role.name = "AI助手2"
                // role.avatar = "https://example.com/avatar.png"
                // role.prompt = "你是一个AI助手，请回答用户的问题。"
                // role.settings = """
                // {
                // "speaker": {
                //     "id": "zh-CN-XiaoyiNeural",
                //     "engine": "晓伊"
                // },
                // "model": {
                //     "id": "gpt-4"
                // },
                // "temperature": 0.8
                // }
                // """
                // role.created_at = Date()
                // do {
                // try context.save()
                // } catch {
                //     print("Error saving role: \(error)")
                // }

        // 检查网络状态变化
        NotificationCenter.default.addObserver(forName: .networkStatusChanged,
                                            object: nil,
                                            queue: .main) { notification in
            if let isConnected = notification.object as? Bool {
                print("Network status changed: \(isConnected ? "Connected" : "Disconnected")")
            }
        }
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView(model: ContentViewModel(store: store, config: config))
                .environment(\.managedObjectContext, container.viewContext)
                .environmentObject(store)
                .environmentObject(config)
                .environmentObject(networkManager)
        }
    }
}

// 添加通知名称
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

