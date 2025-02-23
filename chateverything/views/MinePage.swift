import SwiftUI

struct MineView: View {
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    // 个人信息卡片
                    ProfileCard()
                    
                    // 设置列表
                    SettingsList()
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Gradients.backgroundGradient)
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
        VStack(spacing: DesignSystem.Spacing.large) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                // 头像
                ZStack {
                    Circle()
                        .fill(DesignSystem.Gradients.avatarBackgroundGradient)
                        .frame(width: DesignSystem.AvatarSize.large, height: DesignSystem.AvatarSize.large)
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DesignSystem.AvatarSize.large - 10, height: DesignSystem.AvatarSize.large - 10)
                        .foregroundStyle(DesignSystem.Gradients.avatarForegroundGradient)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    // 昵称和认证标识
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("用户昵称")
                            .font(DesignSystem.Typography.headingSmall)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .font(DesignSystem.Typography.bodySmall)
                    }
                    
                    // 会员标识
                    if isPremium {
                        HStack(spacing: DesignSystem.Spacing.xxxSmall) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Premium")
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundStyle(DesignSystem.Gradients.premiumGradient)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xSmall)
                        .padding(.vertical, DesignSystem.Spacing.xxxSmall)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(DesignSystem.Radius.small)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            
            // 经验条
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景条
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        // 进度条
                        Capsule()
                            .fill(DesignSystem.Gradients.primaryGradient)
                            .frame(width: geometry.size.width * expPercentage, height: 12)
                    }
                    .overlay(
                        HStack {
                            Text("Lv.\(level)")
                                .font(DesignSystem.Typography.small)
                            Text("\(currentExp)/\(maxExp)")
                                .font(DesignSystem.Typography.small)
                        }
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                    )
                }
            }
            .frame(height: 12)
            .padding(.horizontal, DesignSystem.Spacing.medium)
        }
        .padding(.vertical, DesignSystem.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.background)
                .shadow(
                    color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y
                )
        )
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
                
                SettingsRow(icon: "waveform", title: "语音设置", showDivider: true)
                SettingsRow(icon: "gear", title: "通用设置", showDivider: true)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.background)
                .shadow(
                    color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y
                )
        )
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
                    .foregroundStyle(DesignSystem.Gradients.iconGradient)
                    .frame(width: 30)
                
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            
            if showDivider {
                Divider()
                    .padding(.leading, 46)
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

struct MineView_Previews: PreviewProvider {
    static var previews: some View {
        MineView()
    }
}
