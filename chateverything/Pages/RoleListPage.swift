import SwiftUI

enum RoleCategory: String, CaseIterable {
    case daily = "日常生活"
    case business = "商务职场"
    case travel = "旅游出行"
    case study = "学习教育"
}

struct RoleListPage: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var path: NavigationPath
    var config: Config

    @State private var roles: [RoleBiz] = []
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 1, y: 1)
    @State private var selectedChat: ChatSessionBiz?
    @State private var selectedCategory: RoleCategory = .daily

    init(path: Binding<NavigationPath>, config: Config) {
        self.config = config
        _path = path
        _roles = State(initialValue: config.roles)
    }

    func handleClickRole(role: RoleBiz) {
        let session = ChatSessionBiz.create(role: role, in: self.config.store)
        ChatSessionMemberBiz.create(role: role, session: session, in: self.config.store)
        ChatSessionMemberBiz.create(role: self.config.me, session: session, in: self.config.store)
        self.path.append(Route.ChatDetailView(sessionId: session.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(RoleCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category.rawValue)
                                .font(DesignSystem.Typography.bodyMedium)
                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                .padding(.vertical, DesignSystem.Spacing.small)
                                .background {
                                    if selectedCategory == category {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                                            .fill(DesignSystem.Colors.primaryGradient)
                                    } else {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                                            .fill(DesignSystem.Colors.secondary.opacity(0.2))
                                    }
                                }
                                .foregroundColor(selectedCategory == category ? .white : DesignSystem.Colors.textPrimary)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(roles) { role in
                        RoleCardInListPage(role: role, onTap: {
                            handleClickRole(role: role)
                        }, onSecondaryTap: {
                            path.append(Route.RoleDetailView(roleId: role.id))
                        })
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.background)
        }
    }
}

struct RoleCardInListPage: View {
    let role: RoleBiz
    let onTap: () -> Void
    let onSecondaryTap: () -> Void
    
    @State private var isPressed = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Avatar(
                    uri: role.avatar,
                    size: DesignSystem.AvatarSize.large
                )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(role.name)
                        .font(DesignSystem.Typography.headingSmall)
                    // Spacer()
                    // Text(role.config.voice[])
                    //     .font(DesignSystem.Typography.bodySmall)
                    //     .padding(.horizontal, DesignSystem.Spacing.small)
                    //     .padding(.vertical, DesignSystem.Spacing.xxSmall)
                    //     .background(DesignSystem.Colors.secondary.opacity(0.2))
                    //     .cornerRadius(DesignSystem.Radius.small)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            
            Text(role.desc)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(3)
                .padding(.leading, DesignSystem.Spacing.xxxSmall)
            
            Divider()
            
            HStack {
                Button(action: onTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "message.fill")
                        Text("开始聊天")
                        .font(DesignSystem.Typography.bodySmall)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                Button(action: onSecondaryTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "info.circle")
                        Text("详情")
                        .font(DesignSystem.Typography.bodySmall)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.cardPadding)
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        .shadow()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}
