import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var model: ChoreModel
    @Binding var showingThemeSettings: Bool
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con información del usuario
                    UserProfileCard()
                    
                    // Sección de personalización
                    VStack(spacing: 16) {
                        SectionHeader(title: "Personalización", subtitle: "Configura la apariencia de la app")
                        
                        SettingsCard(
                            icon: "paintpalette.fill",
                            title: "Temas y Colores",
                            subtitle: "Personaliza la apariencia",
                            accentColor: themeManager.currentAccentColor
                        ) {
                            HapticManager.shared.lightImpact()
                            showingThemeSettings = true
                        }
                    }
                    
                    // Sección de datos
                    VStack(spacing: 16) {
                        SectionHeader(title: "Datos", subtitle: "Gestiona tu información")
                        
                        VStack(spacing: 12) {
                            SettingsCard(
                                icon: "icloud.fill",
                                title: "Respaldo y Sincronización",
                                subtitle: "Próximamente disponible",
                                accentColor: .blue,
                                isDisabled: true
                            ) {
                                // Función futura
                            }
                            
                            SettingsCard(
                                icon: "trash.fill",
                                title: "Gestión de Datos",
                                subtitle: "Exportar, importar o limpiar datos",
                                accentColor: .orange
                            ) {
                                HapticManager.shared.lightImpact()
                                showingDataManagement = true
                            }
                        }
                    }
                    
                    // Sección de información
                    VStack(spacing: 16) {
                        SectionHeader(title: "Información", subtitle: "Acerca de la aplicación")
                        
                        VStack(spacing: 12) {
                            SettingsCard(
                                icon: "info.circle.fill",
                                title: "Acerca de Lista Pendientes",
                                subtitle: "Versión, desarrollador y más",
                                accentColor: .purple
                            ) {
                                HapticManager.shared.lightImpact()
                                showingAbout = true
                            }
                            
                            SettingsCard(
                                icon: "heart.fill",
                                title: "Calificar la App",
                                subtitle: "Ayúdanos con una reseña",
                                accentColor: .pink
                            ) {
                                HapticManager.shared.lightImpact()
                                // Abrir App Store para calificar
                                if let url = URL(string: "https://apps.apple.com/app/id-your-app-id") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    
                    // Estadísticas rápidas
                    QuickStatsCard()
                    
                    // Espaciado final
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - User Profile Card
struct UserProfileCard: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.currentAccentColor.opacity(0.3), themeManager.currentAccentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(String(model.userName.prefix(1).uppercased()))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(themeManager.currentAccentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("¡Hola, \(model.userName)!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text("Gestiona tu productividad")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.themeColors.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: themeManager.currentAccentColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Settings Card
struct SettingsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let isDisabled: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    init(icon: String, title: String, subtitle: String, accentColor: Color, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isDisabled ? 0.1 : 0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor.opacity(isDisabled ? 0.5 : 1.0))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary.opacity(isDisabled ? 0.6 : 1.0))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary.opacity(isDisabled ? 0.6 : 1.0))
                }
                
                Spacer()
                
                if !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.themeColors.border, lineWidth: 1)
                    )
            )
            .opacity(isDisabled ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Quick Stats Card
struct QuickStatsCard: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var themeManager: ThemeManager
    
    private var totalTasks: Int {
        model.tasks.count
    }
    
    private var completedToday: Int {
        model.todayRecord.completedCount
    }
    
    private var totalCategories: Int {
        model.categories.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Resumen Rápido", subtitle: "Tu progreso en números")
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Tareas",
                    value: "\(totalTasks)",
                    icon: "list.bullet",
                    color: themeManager.currentAccentColor
                )
                
                StatBox(
                    title: "Hoy",
                    value: "\(completedToday)",
                    icon: "checkmark.circle.fill",
                    color: themeManager.themeColors.success
                )
                
                StatBox(
                    title: "Categorías",
                    value: "\(totalCategories)",
                    icon: "tag.fill",
                    color: themeManager.themeColors.warning
                )
            }
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(themeManager.themeColors.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(themeManager.themeColors.secondary)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Section Header (reutilizable)
struct SectionHeader: View {
    let title: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager
    
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

// MARK: - Placeholder Views
struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Gestión de Datos")
                    .font(.title)
                    .padding()
                
                Text("Funcionalidad próximamente disponible")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Lista Pendientes")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Versión 1.0")
                    .foregroundStyle(.secondary)
                
                Text("Una aplicación simple y elegante para gestionar tus tareas diarias y mantenerte productivo.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsTabView(showingThemeSettings: .constant(false))
        .environmentObject(ThemeManager.shared)
        .environmentObject(ChoreModel())
}
