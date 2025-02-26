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

// 添加用于十六进制颜色的扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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




extension Dictionary {
    static func assign(_ target: [Key: Value], _ sources: [Key: Value]...) -> [Key: Value] {
        var result = target
        
        for source in sources {
            for (key, value) in source {
                result[key] = value
            }
        }
        
        return result
    }
    
    mutating func assign(_ sources: [Key: Value]...) {
        for source in sources {
            for (key, value) in source {
                self[key] = value
            }
        }
    }
}

extension Dictionary where Key == String {
    func toJSON(pretty: Bool = false) -> String {
        do {
            let options: JSONSerialization.WritingOptions = pretty ? .prettyPrinted : []
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: options)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error converting dictionary to JSON: \(error)")
            return "{}"
        }
    }
    
    static func fromJSON(_ jsonString: String) -> [String: Any] {
        guard let jsonData = jsonString.data(using: .utf8) else { return [:] }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                return dict
            }
            return [:]
        } catch {
            print("Error parsing JSON string to dictionary: \(error)")
            return [:]
        }
    }
}

extension View {
    func primaryShadow() -> some View {
        self.shadow(color: DesignSystem.Shadows.small.color,
                   radius: DesignSystem.Shadows.small.radius,
                   x: DesignSystem.Shadows.small.x,
                   y: DesignSystem.Shadows.small.y)
    }
}

// 用于条件修饰符的 View 扩展
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Shadow 数据结构
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
} 
