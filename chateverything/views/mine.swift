import SwiftUI

struct Ability {
    let name: String
    let value: Double // 0-100
    let angle: Double
    
    var point: CGPoint {
        let radius = value / 100.0
        return CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
    }
}

struct MineView: View {
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 个人信息卡片
                    ProfileCard()
                    
                    // 设置列表
                    SettingsList()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

// 个人信息卡片视图
struct ProfileCard: View {
    let level: Int = 5
    let currentExp: Int = 720
    let maxExp: Int = 1000
    
    var expPercentage: CGFloat {
        CGFloat(currentExp) / CGFloat(maxExp)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 头像和昵称
            VStack(spacing: 12) {
                // 头像
                ZStack {
                    // 头像背景光晕
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // 头像
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // 昵称
                HStack(spacing: 6) {
                    Text("用户昵称")
                        .font(.title3)
                        .bold()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding(.top, 10)
            
            // 经验条
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景条
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        // 进度条
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * expPercentage, height: 12)
                    }
                    .overlay(
                        HStack {
                            Text("Lv.\(level)")
                                .font(.system(size: 10, weight: .medium))
                            Text("\(currentExp)/\(maxExp)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                    )
                }
            }
            .frame(height: 12)
            .padding(.horizontal)
            
            // 能力雷达图
            AbilityRadarChart(abilities: [
                .init(name: "听力", value: 85, angle: .pi / 2),
                .init(name: "口语", value: 75, angle: .pi * 7 / 6),
                .init(name: "写作", value: 65, angle: .pi * 11 / 6),
                .init(name: "阅读", value: 90, angle: 0)
            ])
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// 设置列表视图
struct SettingsList: View {
    var body: some View {
        VStack(spacing: 1) {
            Group {
                NavigationLink {
                    LanguageModelSettingsView()
                } label: {
                    SettingsRow(icon: "brain", title: "语言模型", showDivider: true)
                }
                
                SettingsRow(icon: "waveform", title: "发音设置", showDivider: true)
                SettingsRow(icon: "gear", title: "通用设置", showDivider: true)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// 设置列表行视图
struct SettingsRow: View {
    let icon: String
    let title: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            if showDivider {
                Divider()
                    .padding(.leading, 46)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct MineView_Previews: PreviewProvider {
    static var previews: some View {
        MineView()
    }
}

// 将原来的 AbilityRadarChart 替换为以下代码

struct AbilityRadarChart: View {
    let abilities: [Ability]
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            
            ZStack {
                RadarGridView(abilities: abilities, size: size, center: center)
                RadarValueArea(abilities: abilities, size: size, center: center)
                RadarAxesView(abilities: abilities, size: size, center: center)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// 背景网格视图
private struct RadarGridView: View {
    let abilities: [Ability]
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        ForEach(0..<5) { level in
            RadarGridLevel(
                level: level,
                abilities: abilities,
                size: size,
                center: center
            )
        }
    }
}

private struct RadarGridLevel: View {
    let level: Int
    let abilities: [Ability]
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        let scale = CGFloat(level + 1) / 5
        RadarPath(abilities: abilities, size: size, center: center, scale: scale)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
}

// 能力值区域视图
private struct RadarValueArea: View {
    let abilities: [Ability]
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        RadarPath(abilities: abilities, size: size, center: center, scale: 1.0)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// 轴线和标签视图
private struct RadarAxesView: View {
    let abilities: [Ability]
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        ForEach(abilities.indices, id: \.self) { index in
            let ability = abilities[index]
            RadarAxisLine(ability: ability, size: size, center: center)
            RadarAxisLabel(ability: ability, size: size, center: center)
        }
    }
}

private struct RadarAxisLine: View {
    let ability: Ability
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + cos(ability.angle) * size/2,
                y: center.y + sin(ability.angle) * size/2
            ))
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
}

private struct RadarAxisLabel: View {
    let ability: Ability
    let size: CGFloat
    let center: CGPoint
    
    var body: some View {
        Text(ability.name)
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .position(
                x: center.x + cos(ability.angle) * size/2 * 1.2,
                y: center.y + sin(ability.angle) * size/2 * 1.2
            )
    }
}

// 雷达图路径
private struct RadarPath: Shape {
    let abilities: [Ability]
    let size: CGFloat
    let center: CGPoint
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (index, ability) in abilities.enumerated() {
            let point = CGPoint(
                x: center.x + ability.point.x * size/2 * scale,
                y: center.y + ability.point.y * size/2 * scale
            )
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}
