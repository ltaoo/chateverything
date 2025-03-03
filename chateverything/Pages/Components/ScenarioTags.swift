import SwiftUI

struct ScenarioTags: View {
    let tags: [String]
    
    // 语言代码到中文名称的映射
    private let languageMap: [String: String] = [
        "en-US": "美式英语",
        "en-GB": "英式英语",
        "zh-CN": "简体中文",
        "ja-JP": "日语",
        // 可以继续添加其他语言映射
    ]
    
    // 难度等级对应的颜色
    private func difficultyColor(_ level: String) -> Color {
        switch level {
            case "A1", "A2":
                return .green
            case "B1", "B2":
                return .blue
            case "C1", "C2":
                return .orange
            default:
                return DesignSystem.Colors.textSecondary
        }
    }
    
    // 检查是否为时间标签
    private func isTimeTag(_ tag: String) -> Bool {
        return tag.contains("min") || tag.contains("sec")
    }
    
    // 检查是否为难度等级标签
    private func isDifficultyTag(_ tag: String) -> Bool {
        return tag.range(of: #"^[ABC][12]$"#, options: .regularExpression) != nil
    }
    
    // 获取标签显示文本
    private func getDisplayText(_ tag: String) -> String {
        if let languageName = languageMap[tag] {
            return languageName
        }
        return tag
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.xxSmall) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    if isTimeTag(tag) {
                        Image(systemName: "clock")
                            .font(DesignSystem.Typography.caption)
                    }
                    
                    Text(getDisplayText(tag))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(isDifficultyTag(tag) ? .white : DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.xSmall)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                        .fill(isDifficultyTag(tag) ? difficultyColor(tag) : DesignSystem.Colors.secondaryBackground)
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ScenarioTags(tags: ["A1", "B2", "C2"])
        ScenarioTags(tags: ["en-US", "5min", "beginner"])
        ScenarioTags(tags: ["ja-JP", "30sec", "advanced"])
    }
    .padding()
} 
