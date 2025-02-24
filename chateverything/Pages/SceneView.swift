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
}

struct SceneView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: SceneCategory = .daily
    
    
    // 场景数据
    let scenarios: [LearningScenario] = [
        // 日常生活场景
        LearningScenario(title: "At the Restaurant", description: "餐厅用餐场景对话", category: .daily),
        LearningScenario(title: "Shopping", description: "购物场景对话", category: .daily),
        LearningScenario(title: "Making Friends", description: "社交场景对话", category: .daily),
        
        // 商务职场场景
        LearningScenario(title: "Job Interview", description: "求职面试对话", category: .business),
        LearningScenario(title: "Business Meeting", description: "商务会议对话", category: .business),
        LearningScenario(title: "Office Communication", description: "办公室交流", category: .business),
        
        // 旅游场景
        LearningScenario(title: "At the Airport", description: "机场场景对话", category: .travel),
        LearningScenario(title: "Hotel Check-in", description: "酒店入住对话", category: .travel),
        LearningScenario(title: "Asking Directions", description: "问路场景对话", category: .travel),
        
        // 学习场景
        LearningScenario(title: "In the Classroom", description: "课堂场景对话", category: .study),
        LearningScenario(title: "Group Discussion", description: "小组讨论对话", category: .study),
        LearningScenario(title: "Library", description: "图书馆场景对话", category: .study)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
//            HStack {
//                Text("英语学习场景")
//                    .font(DesignSystem.Typography.headingMedium)
//                Spacer()
//            }
//            .padding(DesignSystem.Spacing.medium) 

            CategoryTabBar(selectedCategory: $selectedCategory)
            
            #if os(iOS)
            TabView(selection: $selectedCategory) {
                ForEach(SceneCategory.allCases, id: \.self) { category in
                    ScenarioList(scenarios: scenarios.filter { $0.category == category })
                        .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.accent.opacity(0.1),
                        DesignSystem.Colors.accent.opacity(0.2),
                        colorScheme == .dark 
                            ? Color.black.opacity(0.6) 
                            : DesignSystem.Colors.accent.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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
                        SceneCategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { 
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        )
                        .id(category) // Add id for ScrollViewReader
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

struct SceneCategoryButton: View {
    let category: SceneCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(DesignSystem.Typography.bodyMedium)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                            .fill(DesignSystem.Colors.primaryGradient)
                    } else {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                            .fill(DesignSystem.Colors.secondary.opacity(0.2))
                    }
                }
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
        }
    }
}

struct ScenarioList: View {
    let scenarios: [LearningScenario]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(scenarios) { scenario in
                    NavigationLink(destination: Text("场景详情页面待开发")) {
                        ScenarioRow(scenario: scenario)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct ScenarioRow: View {
    let scenario: LearningScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
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
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.medium)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.background)
                .shadow(
                    color: DesignSystem.Shadows.small.color,
                    radius: DesignSystem.Shadows.small.radius,
                    x: DesignSystem.Shadows.small.x,
                    y: DesignSystem.Shadows.small.y
                )
        )
    }
}

// MARK: - Preview
struct SceneView_Previews: PreviewProvider {
    static var previews: some View {
        SceneView()
    }
}
