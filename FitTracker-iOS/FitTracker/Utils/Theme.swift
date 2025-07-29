import SwiftUI

// MARK: - Theme System
struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color.black
        static let secondary = Color.white
        static let accent = Color.blue
        
        // Background Colors
        static let background = Color.white
        static let secondaryBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
        static let cardBackground = Color.white
        
        // Text Colors
        static let primaryText = Color.black
        static let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
        static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
        
        // Border Colors
        static let border = Color(red: 0.9, green: 0.9, blue: 0.9)
        static let separator = Color(red: 0.95, green: 0.95, blue: 0.95)
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Gray Scale
        static let gray50 = Color(red: 0.98, green: 0.98, blue: 0.98)
        static let gray100 = Color(red: 0.95, green: 0.95, blue: 0.95)
        static let gray200 = Color(red: 0.9, green: 0.9, blue: 0.9)
        static let gray300 = Color(red: 0.85, green: 0.85, blue: 0.85)
        static let gray400 = Color(red: 0.7, green: 0.7, blue: 0.7)
        static let gray500 = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let gray600 = Color(red: 0.4, green: 0.4, blue: 0.4)
        static let gray700 = Color(red: 0.3, green: 0.3, blue: 0.3)
        static let gray800 = Color(red: 0.2, green: 0.2, blue: 0.2)
        static let gray900 = Color.black
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Sizes
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption1 = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
        
        // Custom Font Weights
        static let light = Font.system(size: 17, weight: .light)
        static let regular = Font.system(size: 17, weight: .regular)
        static let medium = Font.system(size: 17, weight: .medium)
        static let semibold = Font.system(size: 17, weight: .semibold)
        static let bold = Font.system(size: 17, weight: .bold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Shadow Structure
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(
                color: Theme.Shadows.small.color,
                radius: Theme.Shadows.small.radius,
                x: Theme.Shadows.small.x,
                y: Theme.Shadows.small.y
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.secondary)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func textFieldStyle() -> some View {
        modifier(TextFieldStyle())
    }
}

// MARK: - Color Extensions
extension Color {
    static let theme = Theme.Colors.self
} 