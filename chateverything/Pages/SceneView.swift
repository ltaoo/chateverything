import SwiftUI

// 场景分类
enum SceneCategory: String, CaseIterable {
    case daily = "日常生活"
    case business = "商务职场"
    case travel = "旅游出行"
    case study = "学习教育"
}

// 场景数据结构
struct LearningScenario: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: SceneCategory
    let background: String?
}

struct SceneView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: SceneCategory = .daily
    
    
    // 场景数据
    let scenarios: [LearningScenario] = [
        // 日常生活场景
        LearningScenario(title: "At the Restaurant", description: "餐厅用餐场景对话", category: .daily, background: "background1"),
        LearningScenario(title: "Shopping", description: "购物场景对话", category: .daily, background: nil),
        LearningScenario(title: "Making Friends", description: "社交场景对话", category: .daily, background: nil),
        
        // 商务职场场景
        LearningScenario(title: "Job Interview", description: "求职面试对话", category: .business, background: nil),
        LearningScenario(title: "Business Meeting", description: "商务会议对话", category: .business, background: nil),
        LearningScenario(title: "Office Communication", description: "办公室交流", category: .business, background: nil),
        
        // 旅游场景
        LearningScenario(title: "At the Airport", description: "机场场景对话", category: .travel, background: nil),
        LearningScenario(title: "Hotel Check-in", description: "酒店入住对话", category: .travel, background: nil),
        LearningScenario(title: "Asking Directions", description: "问路场景对话", category: .travel, background: nil),
        
        // 学习场景
        LearningScenario(title: "In the Classroom", description: "课堂场景对话", category: .study, background: nil),
        LearningScenario(title: "Group Discussion", description: "小组讨论对话", category: .study, background: nil),
        LearningScenario(title: "Library", description: "图书馆场景对话", category: .study, background: nil)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            CategoryTabBar(selectedCategory: $selectedCategory)
            
            #if os(iOS)
            TabView(selection: $selectedCategory) {
                ForEach(SceneCategory.allCases, id: \.self) { category in
                    ScenarioList(scenarios: scenarios.filter { $0.category == category })
                        .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(DesignSystem.Colors.background)
            #else
            // For macOS, use a simple view switch
            ForEach(SceneCategory.allCases, id: \.self) { category in
                if category == selectedCategory {
                    ScenarioList(scenarios: scenarios.filter { $0.category == category })
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
                                .foregroundColor(selectedCategory == category ? .white : DesignSystem.Colors.textPrimary)
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
    let onTap: () -> Void
    let onSecondaryTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // 标题和描述部分
            HStack(spacing: DesignSystem.Spacing.medium) {
                // 场景图标
                Circle()
                    .fill(DesignSystem.Gradients.iconGradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.white)
                            .font(DesignSystem.Typography.bodyMedium)
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(scenario.title)
                        .font(DesignSystem.Typography.headingSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(scenario.description)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    HStack(spacing: DesignSystem.Spacing.small) {
                        Circle()
                            .fill(DesignSystem.Colors.secondary.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            )
                        
                        Text("Native Teacher")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()
            }
            
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

                Button(action: onTap) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("开始对话")
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
    }
}


struct ScenarioList: View {
    let scenarios: [LearningScenario]

    @State private var detailVisible: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(scenarios) { scenario in
                    ScenarioCardInListPage(scenario: scenario, onTap: {
                        // 开始对话
                    }, onSecondaryTap: {
                        detailVisible = true
                    })
                }
            }
            .padding()
        }
        .sheet(isPresented: $detailVisible) {
            ScenarioDetailView(scenario: scenarios[0])
        }
    }
}

struct ScenarioDetailView: View {
    let scenario: LearningScenario

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
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.large)
        }
    }
}


// MARK: - Preview
struct SceneView_Previews: PreviewProvider {
    static var previews: some View {
        SceneView()
    }
}
