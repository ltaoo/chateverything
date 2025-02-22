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

struct UserAbilityView: View {
    var body: some View {

            AbilityRadarChart(abilities: [
                .init(name: "听力", value: 85, angle: -.pi/2),                    // 90° (正上方)
                .init(name: "口语", value: 75, angle: -.pi/2 + .pi * 2/5),        // 162°
                .init(name: "写作", value: 65, angle: -.pi/2 + .pi * 4/5),        // 234°
                .init(name: "词汇", value: 80, angle: -.pi/2 + .pi * 6/5),        // 306°
                .init(name: "阅读", value: 90, angle: -.pi/2 + .pi * 8/5),        // 18°
            ])
            .frame(height: 200)
            .padding(.horizontal)
    }
}

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
        ZStack {
            // 100%位置的五边形连线
            Path { path in
                for i in 0..<5 {
                    let angle = -.pi/2 + .pi * 2/5 * Double(i)
                    let point = CGPoint(
                        x: center.x + cos(angle) * size/2,
                        y: center.y + sin(angle) * size/2
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .stroke(.white.opacity(0.2), lineWidth: 1)
            
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

