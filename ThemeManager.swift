import SwiftUI
import Foundation

/// Enum para los diferentes temas disponibles
enum AppTheme: String, CaseIterable, Codable {
    case system = "Sistema"
    case light = "Claro"
    case dark = "Oscuro"
    case ocean = "Océano"
    case forest = "Bosque"
    case sunset = "Atardecer"
    case midnight = "Medianoche"
    case lavender = "Lavanda"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .system: return "gearshape.fill"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .ocean: return "drop.fill"
        case .forest: return "leaf.fill"
        case .sunset: return "sun.haze.fill"
        case .midnight: return "moon.stars.fill"
        case .lavender: return "sparkles"
        }
    }
}

/// Enum para colores de acento personalizados
enum AccentColor: String, CaseIterable, Codable {
    case blue = "Azul"
    case green = "Verde"
    case orange = "Naranja"
    case purple = "Morado"
    case pink = "Rosa"
    case red = "Rojo"
    case teal = "Turquesa"
    case indigo = "Índigo"
    case yellow = "Amarillo"
    case mint = "Menta"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        case .mint: return .mint
        }
    }
    
    var icon: String {
        switch self {
        case .blue: return "drop.fill"
        case .green: return "leaf.fill"
        case .orange: return "flame.fill"
        case .purple: return "gem"
        case .pink: return "heart.fill"
        case .red: return "exclamationmark.triangle.fill"
        case .teal: return "wave.3.right"
        case .indigo: return "moon.fill"
        case .yellow: return "sun.max.fill"
        case .mint: return "snowflake"
        }
    }
}

/// Manager para manejar temas y personalización visual
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
            updateSystemAppearance()
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet {
            saveAccentColor()
        }
    }
    
    @Published var useCustomColors: Bool {
        didSet {
            saveCustomColorsPreference()
        }
    }
    
    private let themeKey = "selectedTheme"
    private let accentColorKey = "selectedAccentColor"
    private let customColorsKey = "useCustomColors"
    
    private init() {
        // Cargar tema guardado
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
        
        // Cargar color de acento guardado
        if let savedAccentColor = UserDefaults.standard.string(forKey: accentColorKey),
           let accentColor = AccentColor(rawValue: savedAccentColor) {
            self.accentColor = accentColor
        } else {
            self.accentColor = .blue
        }
        
        // Cargar preferencia de colores personalizados
        self.useCustomColors = UserDefaults.standard.bool(forKey: customColorsKey)
        
        updateSystemAppearance()
    }
    
    // MARK: - Theme Colors
    
    /// Obtiene los colores del tema actual
    var themeColors: ThemeColors {
        switch currentTheme {
        case .system:
            return SystemThemeColors()
        case .light:
            return LightThemeColors()
        case .dark:
            return DarkThemeColors()
        case .ocean:
            return OceanThemeColors()
        case .forest:
            return ForestThemeColors()
        case .sunset:
            return SunsetThemeColors()
        case .midnight:
            return MidnightThemeColors()
        case .lavender:
            return LavenderThemeColors()
        }
    }
    
    /// Color de acento actual (personalizado o del tema)
    var currentAccentColor: Color {
        return useCustomColors ? accentColor.color : themeColors.accent
    }
    
    // MARK: - Private Methods
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        HapticManager.shared.selectionChanged()
    }
    
    private func saveAccentColor() {
        UserDefaults.standard.set(accentColor.rawValue, forKey: accentColorKey)
        HapticManager.shared.selectionChanged()
    }
    
    private func saveCustomColorsPreference() {
        UserDefaults.standard.set(useCustomColors, forKey: customColorsKey)
        HapticManager.shared.mediumImpact()
    }
    
    private func updateSystemAppearance() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            switch self.currentTheme {
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            case .light, .ocean, .forest, .sunset, .lavender:
                window.overrideUserInterfaceStyle = .light
            case .dark, .midnight:
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Cambia el tema con animación
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
    
    /// Cambia el color de acento con animación
    func setAccentColor(_ color: AccentColor) {
        withAnimation(.easeInOut(duration: 0.2)) {
            accentColor = color
        }
    }
    
    /// Alterna el uso de colores personalizados
    func toggleCustomColors() {
        withAnimation(.easeInOut(duration: 0.2)) {
            useCustomColors.toggle()
        }
    }
}

// MARK: - Theme Colors Protocol

protocol ThemeColors {
    var background: Color { get }
    var secondaryBackground: Color { get }
    var surface: Color { get }
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var cardBackground: Color { get }
    var border: Color { get }
}

// MARK: - Theme Color Implementations

struct SystemThemeColors: ThemeColors {
    var background: Color { Color(.systemBackground) }
    var secondaryBackground: Color { Color(.secondarySystemBackground) }
    var surface: Color { Color(.systemGray6) }
    var primary: Color { Color(.label) }
    var secondary: Color { Color(.secondaryLabel) }
    var accent: Color { .blue }
    var success: Color { .green }
    var warning: Color { .orange }
    var error: Color { .red }
    var cardBackground: Color { Color(.systemBackground) }
    var border: Color { Color(.separator) }
}

struct LightThemeColors: ThemeColors {
    var background: Color { Color(red: 0.98, green: 0.98, blue: 0.99) }
    var secondaryBackground: Color { Color(red: 0.95, green: 0.95, blue: 0.97) }
    var surface: Color { .white }
    var primary: Color { Color(red: 0.1, green: 0.1, blue: 0.15) }
    var secondary: Color { Color(red: 0.4, green: 0.4, blue: 0.5) }
    var accent: Color { Color(red: 0.0, green: 0.48, blue: 1.0) }
    var success: Color { Color(red: 0.2, green: 0.78, blue: 0.35) }
    var warning: Color { Color(red: 1.0, green: 0.58, blue: 0.0) }
    var error: Color { Color(red: 1.0, green: 0.23, blue: 0.19) }
    var cardBackground: Color { .white }
    var border: Color { Color(red: 0.9, green: 0.9, blue: 0.92) }
}

struct DarkThemeColors: ThemeColors {
    var background: Color { Color(red: 0.05, green: 0.05, blue: 0.07) }
    var secondaryBackground: Color { Color(red: 0.1, green: 0.1, blue: 0.12) }
    var surface: Color { Color(red: 0.15, green: 0.15, blue: 0.17) }
    var primary: Color { Color(red: 0.95, green: 0.95, blue: 0.97) }
    var secondary: Color { Color(red: 0.7, green: 0.7, blue: 0.75) }
    var accent: Color { Color(red: 0.4, green: 0.78, blue: 1.0) }
    var success: Color { Color(red: 0.3, green: 0.85, blue: 0.4) }
    var warning: Color { Color(red: 1.0, green: 0.65, blue: 0.1) }
    var error: Color { Color(red: 1.0, green: 0.35, blue: 0.3) }
    var cardBackground: Color { Color(red: 0.15, green: 0.15, blue: 0.17) }
    var border: Color { Color(red: 0.25, green: 0.25, blue: 0.27) }
}

struct OceanThemeColors: ThemeColors {
    var background: Color { Color(red: 0.95, green: 0.98, blue: 1.0) }
    var secondaryBackground: Color { Color(red: 0.9, green: 0.96, blue: 0.99) }
    var surface: Color { Color(red: 0.98, green: 0.99, blue: 1.0) }
    var primary: Color { Color(red: 0.1, green: 0.3, blue: 0.5) }
    var secondary: Color { Color(red: 0.4, green: 0.6, blue: 0.7) }
    var accent: Color { Color(red: 0.0, green: 0.6, blue: 0.8) }
    var success: Color { Color(red: 0.1, green: 0.7, blue: 0.6) }
    var warning: Color { Color(red: 0.9, green: 0.7, blue: 0.2) }
    var error: Color { Color(red: 0.8, green: 0.3, blue: 0.3) }
    var cardBackground: Color { Color(red: 0.98, green: 0.99, blue: 1.0) }
    var border: Color { Color(red: 0.8, green: 0.9, blue: 0.95) }
}

struct ForestThemeColors: ThemeColors {
    var background: Color { Color(red: 0.96, green: 0.98, blue: 0.95) }
    var secondaryBackground: Color { Color(red: 0.93, green: 0.96, blue: 0.92) }
    var surface: Color { Color(red: 0.98, green: 0.99, blue: 0.97) }
    var primary: Color { Color(red: 0.15, green: 0.3, blue: 0.2) }
    var secondary: Color { Color(red: 0.4, green: 0.6, blue: 0.5) }
    var accent: Color { Color(red: 0.2, green: 0.7, blue: 0.4) }
    var success: Color { Color(red: 0.3, green: 0.8, blue: 0.5) }
    var warning: Color { Color(red: 0.9, green: 0.6, blue: 0.2) }
    var error: Color { Color(red: 0.8, green: 0.4, blue: 0.3) }
    var cardBackground: Color { Color(red: 0.98, green: 0.99, blue: 0.97) }
    var border: Color { Color(red: 0.85, green: 0.9, blue: 0.85) }
}

struct SunsetThemeColors: ThemeColors {
    var background: Color { Color(red: 1.0, green: 0.97, blue: 0.94) }
    var secondaryBackground: Color { Color(red: 0.98, green: 0.94, blue: 0.9) }
    var surface: Color { Color(red: 1.0, green: 0.98, blue: 0.96) }
    var primary: Color { Color(red: 0.3, green: 0.2, blue: 0.15) }
    var secondary: Color { Color(red: 0.6, green: 0.5, blue: 0.4) }
    var accent: Color { Color(red: 1.0, green: 0.5, blue: 0.2) }
    var success: Color { Color(red: 0.8, green: 0.6, blue: 0.2) }
    var warning: Color { Color(red: 1.0, green: 0.7, blue: 0.0) }
    var error: Color { Color(red: 0.9, green: 0.3, blue: 0.2) }
    var cardBackground: Color { Color(red: 1.0, green: 0.98, blue: 0.96) }
    var border: Color { Color(red: 0.9, green: 0.85, blue: 0.8) }
}

struct MidnightThemeColors: ThemeColors {
    var background: Color { Color(red: 0.02, green: 0.05, blue: 0.1) }
    var secondaryBackground: Color { Color(red: 0.05, green: 0.08, blue: 0.15) }
    var surface: Color { Color(red: 0.08, green: 0.12, blue: 0.2) }
    var primary: Color { Color(red: 0.9, green: 0.95, blue: 1.0) }
    var secondary: Color { Color(red: 0.6, green: 0.7, blue: 0.8) }
    var accent: Color { Color(red: 0.4, green: 0.6, blue: 1.0) }
    var success: Color { Color(red: 0.2, green: 0.8, blue: 0.6) }
    var warning: Color { Color(red: 1.0, green: 0.7, blue: 0.2) }
    var error: Color { Color(red: 1.0, green: 0.4, blue: 0.4) }
    var cardBackground: Color { Color(red: 0.08, green: 0.12, blue: 0.2) }
    var border: Color { Color(red: 0.15, green: 0.2, blue: 0.3) }
}

struct LavenderThemeColors: ThemeColors {
    var background: Color { Color(red: 0.98, green: 0.96, blue: 1.0) }
    var secondaryBackground: Color { Color(red: 0.95, green: 0.93, blue: 0.98) }
    var surface: Color { Color(red: 0.99, green: 0.98, blue: 1.0) }
    var primary: Color { Color(red: 0.2, green: 0.15, blue: 0.3) }
    var secondary: Color { Color(red: 0.5, green: 0.4, blue: 0.6) }
    var accent: Color { Color(red: 0.6, green: 0.4, blue: 0.8) }
    var success: Color { Color(red: 0.5, green: 0.7, blue: 0.5) }
    var warning: Color { Color(red: 0.9, green: 0.6, blue: 0.4) }
    var error: Color { Color(red: 0.8, green: 0.4, blue: 0.5) }
    var cardBackground: Color { Color(red: 0.99, green: 0.98, blue: 1.0) }
    var border: Color { Color(red: 0.9, green: 0.85, blue: 0.95) }
}

// MARK: - Environment Key for Theme

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theming

extension View {
    /// Aplica el tema actual a la vista
    func themed() -> some View {
        self.environment(\.themeManager, ThemeManager.shared)
    }
    
    /// Aplica colores del tema actual como fondo
    func themedBackground() -> some View {
        self.background(ThemeManager.shared.themeColors.background)
    }
    
    /// Aplica el color de acento actual
    func themedAccent() -> some View {
        self.accentColor(ThemeManager.shared.currentAccentColor)
    }
}
