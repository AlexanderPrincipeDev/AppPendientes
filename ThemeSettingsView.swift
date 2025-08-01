import SwiftUI

struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingThemePreview = false
    @State private var previewTheme: AppTheme = .system
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con preview del tema actual
                    ThemePreviewCard(theme: themeManager.currentTheme)
                    
                    // Sección de temas
                    VStack(spacing: 16) {
                        SectionHeader(title: "Temas", subtitle: "Personaliza la apariencia de la aplicación")
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                ThemeCard(
                                    theme: theme,
                                    isSelected: themeManager.currentTheme == theme
                                ) {
                                    HapticManager.shared.selection()
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        themeManager.setTheme(theme)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sección de colores de acento
                    VStack(spacing: 16) {
                        SectionHeader(title: "Color de Acento", subtitle: "Elige el color principal de la interfaz")
                        
                        VStack(spacing: 12) {
                            // Toggle para usar colores personalizados
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Colores Personalizados")
                                        .font(.headline)
                                        .foregroundStyle(themeManager.themeColors.primary)
                                    
                                    Text("Usar colores de acento personalizados en lugar del tema")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.themeColors.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.useCustomColors)
                                    .toggleStyle(CustomToggleStyle())
                            }
                            .padding(16)
                            .background(themeManager.themeColors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            
                            // Grid de colores de acento (solo visible si está habilitado)
                            if themeManager.useCustomColors {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                    ForEach(AccentColor.allCases, id: \.self) { accentColor in
                                        AccentColorButton(
                                            accentColor: accentColor,
                                            isSelected: themeManager.accentColor == accentColor
                                        ) {
                                            HapticManager.shared.lightImpact()
                                            themeManager.setAccentColor(accentColor)
                                        }
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    
                    // Información adicional
                    VStack(spacing: 12) {
                        InfoCard(
                            icon: "lightbulb.fill",
                            title: "Tip",
                            description: "Los temas se aplican inmediatamente y se guardan automáticamente. Algunos temas funcionan mejor con el modo claro u oscuro del sistema.",
                            color: themeManager.currentAccentColor
                        )
                        
                        InfoCard(
                            icon: "paintpalette.fill",
                            title: "Personalización",
                            description: "Puedes combinar cualquier tema con cualquier color de acento para crear tu estilo único.",
                            color: themeManager.themeColors.success
                        )
                    }
                    
                    // Espaciado final
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Temas y Colores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        HapticManager.shared.buttonPress()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
                }
            }
        }
        .themedAccent()
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let theme: AppTheme
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tema Actual")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Text(theme.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(themeManager.currentAccentColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundStyle(themeManager.currentAccentColor)
                }
            }
            
            // Mini preview de la interfaz
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == 0 ? themeManager.currentAccentColor : themeManager.themeColors.surface)
                        .frame(height: 8)
                        .frame(maxWidth: index == 0 ? .infinity : 40)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
                .shadow(color: themeManager.currentAccentColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    private var themeColors: ThemeColors {
        switch theme {
        case .system: return SystemThemeColors()
        case .light: return LightThemeColors()
        case .dark: return DarkThemeColors()
        case .ocean: return OceanThemeColors()
        case .forest: return ForestThemeColors()
        case .sunset: return SunsetThemeColors()
        case .midnight: return MidnightThemeColors()
        case .lavender: return LavenderThemeColors()
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Preview de colores del tema
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeColors.background)
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeColors.surface)
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeColors.accent)
                        .frame(height: 20)
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: theme.icon)
                            .font(.caption)
                            .foregroundStyle(isSelected ? themeManager.currentAccentColor : themeColors.accent)
                        
                        Text(theme.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(isSelected ? themeManager.currentAccentColor : themeManager.themeColors.primary)
                    }
                    
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(themeManager.currentAccentColor)
                            
                            Text("Activo")
                                .font(.caption2)
                                .foregroundStyle(themeManager.currentAccentColor)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentAccentColor : themeManager.themeColors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Accent Color Button
struct AccentColorButton: View {
    let accentColor: AccentColor
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(accentColor.color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .stroke(themeManager.themeColors.background, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.background)
                }
                
                // Borde exterior
                Circle()
                    .stroke(isSelected ? accentColor.color : themeManager.themeColors.border, lineWidth: 2)
                    .frame(width: 50, height: 50)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Toggle Style
struct CustomToggleStyle: ToggleStyle {
    @StateObject private var themeManager = ThemeManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            HapticManager.shared.lightImpact()
            configuration.isOn.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? themeManager.currentAccentColor : themeManager.themeColors.surface)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(themeManager.themeColors.background)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            HStack {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                Spacer()
            }
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ThemeSettingsView()
}