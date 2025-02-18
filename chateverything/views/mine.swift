import SwiftUI

struct MineView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 个人信息卡片
                ProfileCard()
                
                // 设置列表
                SettingsList()
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
            // 头像和等级标志
            ZStack(alignment: .bottomTrailing) {
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
                
                // 等级标志
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("Lv.\(level)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 2)
            }
            
            // 用户信息卡片组
            HStack(spacing: 12) {
                // 会员卡片
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("普通会员")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                
                // 签到卡片
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
                    Text("每日签到")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // 昵称和经验信息
            VStack(spacing: 12) {
                HStack {
                    Text("用户昵称")
                        .font(.title3)
                        .bold()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 14))
                }
                
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
                            Text("\(currentExp)/\(maxExp)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        )
                    }
                }
                .frame(height: 12)
                .padding(.horizontal)
            }
            
            // 统计信息卡片组
            HStack(spacing: 15) {
                StatCard(icon: "star.circle.fill", value: "\(currentExp)", title: "积分")
                StatCard(icon: "chart.line.uptrend.xyaxis", value: "Lv.\(level)", title: "等级")
                StatCard(icon: "heart.circle.fill", value: "12", title: "收藏")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// 统计卡片组件
struct StatCard: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// 设置列表视图
struct SettingsList: View {
    var body: some View {
        VStack(spacing: 1) {
            Group {
                SettingsRow(icon: "gear", title: "通用设置", showDivider: true)
                SettingsRow(icon: "bell.badge", title: "消息通知", showDivider: true)
                SettingsRow(icon: "lock.shield", title: "隐私设置", showDivider: true)
                SettingsRow(icon: "questionmark.circle", title: "帮助与反馈", showDivider: true)
                SettingsRow(icon: "info.circle", title: "关于我们", showDivider: false)
            }
        }
        .background(Color(uiColor: .systemBackground))
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
        .background(Color(uiColor: .systemBackground))
    }
}

struct MineView_Previews: PreviewProvider {
    static var previews: some View {
        MineView()
    }
}
