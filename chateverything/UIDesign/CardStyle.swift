import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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

// 为 View 添加扩展方法，使用更方便
extension View {
    func shadow() -> some View {
        modifier(CardStyle())
    }
} 