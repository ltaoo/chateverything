import SwiftUI
import UIKit

struct DiscoverView: View {
    @Binding var path: NavigationPath
    var store: ChatStore

    init(path: Binding<NavigationPath>, store: ChatStore) {
        _path = path
        self.store = store
    }

    // 定义磁贴的颜色主题
    private let tileColors: [Color] = [
        Color(hex: "007AFF"),  // iOS 蓝
        Color(hex: "34C759"),  // iOS 绿
        Color(hex: "FF9500"),  // iOS 橙
        Color(hex: "AF52DE")   // iOS 紫
    ]
    
    // 定义网格布局
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 顶部标语
                Text("开启你的学习之旅")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    // 答题模块 - 大尺寸
                    FeatureTile(
                        title: "答题练习",
                        subtitle: "提升你的英语水平",
                        icon: "questionmark.circle.fill",
                        color: tileColors[0],
                        size: .large
                    ) {
                        print("进入答题模块")
                    }
                    
                    // 单词模块 - 小尺寸
                    FeatureTile(
                        title: "单词学习",
                        subtitle: "记忆更多词汇",
                        icon: "textformat",
                        color: tileColors[1],
                        size: .small
                    ) {
                        print("进入单词模块")
                        path.append(Route.VocabularyView(filepath: "/dicts/CET4_T"))
                    }
                    
                    // 场景对话 - 小尺寸
                    FeatureTile(
                        title: "场景对话",
                        subtitle: "实用对话练习",
                        icon: "bubble.left.and.bubble.right.fill",
                        color: tileColors[2],
                        size: .small
                    ) {
                        print("进入场景对话")
                    }
                    
                    // 雅思模块 - 大尺寸
                    FeatureTile(
                        title: "雅思备考",
                        subtitle: "专业雅思训练",
                        icon: "graduationcap.fill",
                        color: tileColors[3],
                        size: .large
                    ) {
                        print("进入雅思模块")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("发现")
        .background(Color(uiColor: UIColor.systemGroupedBackground))
    }
}

// 磁贴尺寸枚举
enum TileSize {
    case small
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 140
        case .large: return 180
        }
    }
}

// 磁贴组件
struct FeatureTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let size: TileSize
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: size == .large ? 32 : 28))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: size.height)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// 用于创建十六进制颜色的扩展
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
            (a, r, g, b) = (255, 0, 0, 0)
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
