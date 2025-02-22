import SwiftUI


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
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

// 个人信息卡片视图
struct ProfileCard: View {
    let level: Int = 5
    let currentExp: Int = 720
    let maxExp: Int = 1000
    let isPremium: Bool = true
    
    var expPercentage: CGFloat {
        CGFloat(currentExp) / CGFloat(maxExp)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // 昵称和认证标识
                    HStack(spacing: 6) {
                        Text("用户昵称")
                            .font(.title3)
                            .bold()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 14))
                    }
                    
                    // 会员标识
                    if isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Premium")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .yellow]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
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
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
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
