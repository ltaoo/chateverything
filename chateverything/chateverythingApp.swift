//
//  chateverythingApp.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI
import CoreData

@main
struct ChatEverythingApp: App {
//    let persistenceController = PersistenceController.shared
    let chatStore: ChatStore

    init() {
        chatStore = ChatStore(container: PersistenceController.container)

        let context = PersistenceController.container.viewContext
        
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
        RoleEntity.createDefaultRoles(in: context)
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.container.viewContext)
                .environmentObject(chatStore)
        }
    }
}
