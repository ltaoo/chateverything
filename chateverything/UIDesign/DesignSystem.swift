import SwiftUI

enum DesignSystem {
    // MARK: - Colors
    enum Colors {
        // 主要颜色
        static let primary = Color("PrimaryColor")
        static let primaryGradient = LinearGradient(
            colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // 主要颜色的不同透明度版本
        static let primaryLight = primary.opacity(0.1)
        static let primaryMedium = primary.opacity(0.5)
        static let primaryDark = primary.opacity(0.8)
        
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        
        // 背景颜色
        static let background = Color("Background")
        static let secondaryBackground = Color("SecondaryBackgroundColor")
        
        // 文字颜色
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textDisabled = Color("TextDisabledColor")
        
        // 状态颜色
        static let success = Color("SuccessColor")
        static let error = Color("ErrorColor")
        static let warning = Color("WarningColor")
        
        // Add these two colors
        static let primaryGradientStart = Color("PrimaryGradientStart")
        static let primaryGradientEnd = Color("PrimaryGradientEnd")

        static var divider: Color {
            Color.gray.opacity(0.2)
        }
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxxSmall: CGFloat = 2
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 64

        static let cardPadding: CGFloat = 16
        static let xlCardPadding: CGFloat = 24
    }

    // MARK: - Typography
    enum Typography {
        // 动态字体(推荐)
        static let headingLarge = Font.system(size: 32, weight: .bold)
        static let headingMedium = Font.system(size: 24, weight: .bold)
        static let headingSmall = Font.headline
        
        static let bodyLarge = Font.system(size: 18)
        static let bodyMedium = Font.body
        static let bodySmall = Font.subheadline
        
        static let caption = Font.system(size: 12)
        static let small = Font.system(size: 10)
    }
    
    // MARK: - Radius
    enum Radius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let circle: CGFloat = .infinity
        static let xLarge: CGFloat = 24
    }
    
    // MARK: - Shadow
    enum Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        static let medium = Shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        static let large = Shadow(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Gradients
    enum Gradients {
        static let primaryGradient = LinearGradient(
            colors: [Colors.primaryGradientStart, Colors.primaryGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let backgroundGradient = LinearGradient(
            colors: [Color("BackgroundGradientStart"), Color("BackgroundGradientEnd")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let avatarBackgroundGradient = LinearGradient(
            gradient: Gradient(colors: [
                Colors.primary.opacity(0.2),
                Colors.secondary.opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let avatarForegroundGradient = LinearGradient(
            gradient: Gradient(colors: [Colors.primary, Colors.primary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let iconGradient = LinearGradient(
            colors: [Color("IconGradientStart"), Color("IconGradientEnd")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let premiumGradient = LinearGradient(
            gradient: Gradient(colors: [.orange, .yellow]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Avatar Sizes
    enum AvatarSize {
        static let small: CGFloat = 32
        static let medium: CGFloat = 48
        static let large: CGFloat = 56
        static let xLarge: CGFloat = 68
    }
}
