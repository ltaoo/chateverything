//
//  chateverythingApp.swift
//  chateverything
//
//  Created by litao on 2025/2/5.
//

import SwiftUI

// 导入 NavigationStateManager
@main
struct chateverythingApp: App {
    @StateObject private var navigationManager = NavigationStateManager()
    
    var body: some Scene {
        WindowGroup {
            if let currentView = navigationManager.currentView {
                currentView
                    .environmentObject(navigationManager)
            } else {
                ContentView()
                    .environmentObject(navigationManager)
            }
        }
    }
}
