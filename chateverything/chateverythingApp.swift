//
//  chateverythingApp.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI

@main
struct ChatEverythingApp: App {
    let persistenceController = PersistenceController.shared
    let chatStore: ChatStore

    init() {
        chatStore = ChatStore(container: persistenceController.container)
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(chatStore)
        }
    }
}
