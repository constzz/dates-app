import SwiftUI

// MARK: - Design System for Dates MVP
// Clean, functional, modern aesthetic
// True neutrals + single accent for clarity and focus

struct DatesDesign {
    
    // MARK: - Color Palette
    // Monochrome + electric blue accent
    struct Colors {
        // Primary accent - electric blue (sharp, modern, energetic)
        static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentDeep = Color(red: 0.0, green: 0.38, blue: 0.88)
        static let accentSoft = Color(red: 0.93, green: 0.96, blue: 1.0)
        
        // True neutrals (no warm tint)
        static let surface = Color(.systemBackground)
        static let surfaceElevated = Color(.secondarySystemBackground)
        static let border = Color(.separator)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Status colors - functional, not decorative
        static let statusIdea = Color(.systemGray)
        static let statusPlanned = Color(red: 1.0, green: 0.6, blue: 0.0) // Amber
        static let statusCompleted = Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        static let statusArchived = Color(.systemGray3)
    }
    
    // MARK: - Typography
    // Refined hierarchy with clear distinctions
    struct Typography {
        // Display - for hero moments
        static func hero(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Colors.textPrimary)
        }
        
        // Headings
        static func heading1(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Colors.textPrimary)
        }
        
        static func heading2(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Colors.textPrimary)
        }
        
        static func heading3(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Colors.textPrimary)
        }
        
        // Body text
        static func body(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Colors.textPrimary)
                .lineSpacing(4)
        }
        
        static func bodySecondary(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Colors.textSecondary)
                .lineSpacing(4)
        }
        
        // Small text
        static func caption(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Colors.textSecondary)
        }
    }
    
    // MARK: - Spacing Scale
    // 4pt base with semantic names
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let soft = Color.black.opacity(0.04)
        static let medium = Color.black.opacity(0.08)
        static let strong = Color.black.opacity(0.12)
    }
    
    // MARK: - Component Styles
    
    // Premium card style
    struct CardStyle: ViewModifier {
        var elevation: CardElevation = .base
        
        func body(content: Content) -> some View {
            content
                .background(elevation.backgroundColor)
                .cornerRadius(Radius.lg)
                .shadow(color: elevation.shadowColor, radius: elevation.shadowRadius, x: 0, y: elevation.shadowY)
        }
        
        enum CardElevation {
            case base, elevated, prominent
            
            var backgroundColor: Color {
                switch self {
                case .base: return Colors.surface
                case .elevated: return Colors.surfaceElevated
                case .prominent: return Colors.surfaceElevated
                }
            }
            
            var shadowColor: Color {
                switch self {
                case .base: return Shadow.soft
                case .elevated: return Shadow.medium
                case .prominent: return Shadow.strong
                }
            }
            
            var shadowRadius: CGFloat {
                switch self {
                case .base: return 4
                case .elevated: return 8
                case .prominent: return 16
                }
            }
            
            var shadowY: CGFloat {
                switch self {
                case .base: return 2
                case .elevated: return 4
                case .prominent: return 8
                }
            }
        }
    }
    
    // Button styles
    struct PrimaryButton: ButtonStyle {
        var isLoading: Bool = false
        var isDisabled: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(isDisabled ? Colors.textTertiary : Colors.accent)
                .cornerRadius(Radius.md)
                .opacity(configuration.isPressed ? 0.85 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    struct SecondaryButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Colors.accentSoft)
                .cornerRadius(Radius.md)
                .opacity(configuration.isPressed ? 0.7 : 1.0)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    struct GhostButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Colors.accent)
                .opacity(configuration.isPressed ? 0.6 : 1.0)
        }
    }
    
    // Text field style
    struct TextFieldStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.system(size: 17, weight: .regular))
                .padding(Spacing.md)
                .background(Colors.surfaceElevated)
                .cornerRadius(Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(Colors.border, lineWidth: 1)
                )
        }
    }
    
    // Status badge component
    struct StatusBadge: View {
        let status: DateStatus
        
        var body: some View {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold, ))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .cornerRadius(Radius.pill)
        }
        
        var statusColor: Color {
            switch status {
            case .idea: return Colors.statusIdea
            case .planned: return Colors.statusPlanned
            case .completed: return Colors.statusCompleted
            case .archived: return Colors.textSecondary
            }
        }
        
        var statusText: String {
            switch status {
            case .idea: return "Idea"
            case .planned: return "Planned"
            case .completed: return "Completed"
            case .archived: return "Archived"
            }
        }
    }
    
    // Vibe tag component
    struct VibeTag: View {
        let vibe: DateVibe
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(vibeEmoji)
                        .font(.system(size: 16))
                    Text(vibe.label)
                        .font(.system(size: 14, weight: .semibold, ))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Colors.accent : Colors.surface)
                .foregroundColor(isSelected ? .white : Colors.textPrimary)
                .cornerRadius(Radius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .strokeBorder(isSelected ? Color.clear : Colors.border, lineWidth: 1.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        var vibeEmoji: String {
            switch vibe {
            case .easy: return "☕️"
            case .classic: return "🎩"
            case .spontaneous: return "🎲"
            case .adventure: return "🎒"
            case .relaxed: return "🌙"
            case .fancy: return "✨"
            }
        }
    }
    
    // Icon with background component
    struct IconCircle: View {
        let systemName: String
        let color: Color
        var size: CGFloat = 48
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: size, height: size)
                
                Image(systemName: systemName)
                    .font(.system(size: size * 0.45, weight: .regular)) // Tabler-style: lighter weight
                    .foregroundColor(color)
            }
        }
    }
    
    // Tabler-style icon (outlined, consistent stroke)
    struct Icon: View {
        let name: String
        var size: CGFloat = 20
        var color: Color = Colors.textPrimary
        
        var body: some View {
            Image(systemName: sfSymbolMapping[name] ?? name)
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color)
                .imageScale(.medium)
        }
        
        // Map semantic names to SF Symbols with Tabler aesthetic (outlined, not filled)
        private let sfSymbolMapping: [String: String] = [
            "heart": "heart",
            "heart-filled": "heart.fill",
            "user": "person",
            "users": "person.2",
            "calendar": "calendar",
            "clock": "clock",
            "map-pin": "mappin",
            "plus": "plus",
            "x": "xmark",
            "arrow-right": "arrow.right",
            "link": "link",
            "copy": "doc.on.doc",
            "alert-triangle": "exclamationmark.triangle",
            "sparkles": "sparkles",
            "check": "checkmark",
            "archive": "archivebox",
            "lightbulb": "lightbulb",
        ]
    }
}

// MARK: - View Extensions

extension View {
    func datesCard(elevation: DatesDesign.CardStyle.CardElevation = .base) -> some View {
        self.modifier(DatesDesign.CardStyle(elevation: elevation))
    }
}

// MARK: - Custom TextFieldStyle

struct DatesTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 17, weight: .regular))
            .padding(DatesDesign.Spacing.md)
            .background(DatesDesign.Colors.surfaceElevated)
            .cornerRadius(DatesDesign.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DatesDesign.Radius.md)
                    .strokeBorder(DatesDesign.Colors.border, lineWidth: 1.5)
            )
    }
}
