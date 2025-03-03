import SwiftUI

struct SceneView: View {
    @Binding var path: NavigationPath
    let config: Config

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: SceneCategory = .daily

    func handleClickScenario(scenario: LearningScenario) {
        let role = scenario.talker
        let payload = ChatSessionCreatePayload(
            title: scenario.title,
            prompt: "\(scenario.description)\n\(role.prompt)",
            roles: [role, self.config.me]
        )
        let session = ChatSessionBiz.Create(payload: payload, in: self.config.store)
        guard let session = session else {
            return
        }
        self.path.append(Route.ChatDetailView(sessionId: session.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            CategoryTabBar(selectedCategory: $selectedCategory)

            #if os(iOS)
                TabView(selection: $selectedCategory) {
                    ForEach(SceneCategory.allCases, id: \.self) { category in
                        ScenarioList(
                            scenarios: scenarios.filter { $0.category == category }, config: config
                        ) {
                            scenario in
                            handleClickScenario(scenario: scenario)
                        }
                        .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(DesignSystem.Colors.background)
            #else
                // For macOS, use a simple view switch
                ForEach(SceneCategory.allCases, id: \.self) { category in
                    if category == selectedCategory {
                        ScenarioList(
                            scenarios: scenarios.filter { $0.category == category }, config: config
                        ) { scenario in
                            handleClickScenario(scenario: scenario)
                        }
                    }
                }
            #endif
        }
    }
}

// MARK: - 子视图组件
struct CategoryTabBar: View {
    @Binding var selectedCategory: SceneCategory
    @State private var scrollViewProxy: ScrollViewProxy?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(SceneCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category.rawValue)
                                .font(DesignSystem.Typography.bodyMedium)
                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                .padding(.vertical, DesignSystem.Spacing.small)
                                .background {
                                    if selectedCategory == category {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.xLarge)
                                            .fill(DesignSystem.Colors.primary)
                                    } else {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.xLarge)
                                            .fill(DesignSystem.Colors.secondaryBackground)
                                    }
                                }
                                .foregroundColor(
                                    selectedCategory == category
                                        ? .white : DesignSystem.Colors.textPrimary)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .onChange(of: selectedCategory) { newCategory in
                withAnimation {
                    proxy.scrollTo(newCategory, anchor: .center)
                }
            }
        }
    }
}

struct ScenarioCardInListPage: View {
    let scenario: LearningScenario
    let config: Config
    let onTap: (_ scenario: LearningScenario) -> Void

    @State private var detailVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // 标题和描述部分
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(scenario.title)
                        .font(DesignSystem.Typography.headingSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Text(scenario.description)
                        .font(DesignSystem.Typography.bodySmall)
                        .lineLimit(3)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()
               
            }
 
            // 替换原来的标签实现
            ScenarioTags(tags: scenario.tags)

            Divider()

            HStack {
                Spacer()

                Button(action: {
                    detailVisible = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "info.circle")
                        Text("详情")
                            .font(DesignSystem.Typography.bodySmall)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    onTap(scenario)
                }) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "message.fill")
                        Text("开始新对话")
                            .font(DesignSystem.Typography.bodySmall)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.cardPadding)
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        .shadow()
        .sheet(isPresented: $detailVisible) {
            ScenarioDetailView(scenario: scenario, config: config)
        }
    }
}

struct ScenarioList: View {
    let scenarios: [LearningScenario]
    let config: Config

    var onTap: (LearningScenario) -> Void

    @State private var detailVisible: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(scenarios) { scenario in
                    ScenarioCardInListPage(
                        scenario: scenario,
                        config: config,
                        onTap: onTap
                    )
                }
            }
            .padding()
        }
    }
}

struct ScenarioDetailView: View {
    let scenario: LearningScenario
    let config: Config
    private var dialogueMessages: [DialogueMessage] {
        scenario.example.map { example in
            DialogueMessage(
                content: example["content"] ?? "",
                isMe: example["isMe"] == "true"
            )
        }
    }

    var body: some View {
        ScrollView {
            if let background = scenario.background {
                Image(background)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text(scenario.title)
                    .font(DesignSystem.Typography.headingLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(scenario.description)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                // 使用新的对话播放器
                DialoguePlayer(scenario: scenario, dialogues: dialogueMessages, config: config)
            }
            .padding(DesignSystem.Spacing.large)
        }
    }
}
