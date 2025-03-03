import SwiftUI

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
    @State private var searchText = ""

    init(path: Binding<NavigationPath>, config: Config) {
        self.config = config
        _path = path
        _roles = State(initialValue: config.roles.filter { $0.type == "chat" })
    }

    func handleClickRole(role: RoleBiz) {
        let payload = ChatSessionCreatePayload(roles: [role, self.config.me])
        let session = ChatSessionBiz.Create(payload: payload, in: self.config.store)
        guard let session = session else {
            return
        }
        self.path.append(Route.ChatDetailView(sessionId: session.id))
    }

    var filteredRoles: [RoleBiz] {
        if searchText.isEmpty {
            return roles
        }
        return roles.filter { role in
            role.type == "chat"
                && (role.name.localizedCaseInsensitiveContains(searchText)
                    || role.desc.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignSystem.Spacing.small) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    TextField("搜索角色...", text: $searchText)
                        .font(DesignSystem.Typography.bodyMedium)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.xLarge)

                // Button(action: {
                //     path.append(Route.RoleCreateView)
                // }) {
                //     Image(systemName: "plus.circle.fill")
                //         .font(.system(size: 24))
                //         .foregroundColor(DesignSystem.Colors.primary)
                // }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.background)

            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(filteredRoles) { role in
                        if !role.disabled {
                            RoleCardInListPage(
                                role: role,
                                onTap: {
                                    handleClickRole(role: role)
                                },
                                onSecondaryTap: {
                                    path.append(Route.RoleDetailView(roleId: role.id))
                                }
                            )
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: filteredRoles)
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
                Spacer()

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

                Button(action: onTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "message.fill")
                        Text("开始新对话")
                            .font(DesignSystem.Typography.bodySmall)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

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
