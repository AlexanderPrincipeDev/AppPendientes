import SwiftUI

struct PomodoroSettingsView: View {
    @StateObject private var pomodoroManager = PomodoroManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var settings: PomodoroSettings
    
    init() {
        self._settings = State(initialValue: PomodoroManager.shared.settings)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Duración de sesiones
                Section("Duración de Sesiones") {
                    DurationSettingRow(
                        title: "Trabajo",
                        icon: "brain.head.profile",
                        color: .red,
                        duration: $settings.workDuration
                    )
                    
                    DurationSettingRow(
                        title: "Descanso Corto",
                        icon: "cup.and.saucer.fill",
                        color: .green,
                        duration: $settings.shortBreakDuration
                    )
                    
                    DurationSettingRow(
                        title: "Descanso Largo",
                        icon: "bed.double.fill",
                        color: .blue,
                        duration: $settings.longBreakDuration
                    )
                }
                
                // Configuración de ciclos
                Section("Ciclos de Trabajo") {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundStyle(themeManager.currentAccentColor)
                            .frame(width: 24)
                        
                        Text("Sesiones hasta descanso largo")
                        
                        Spacer()
                        
                        Picker("", selection: $settings.sessionsUntilLongBreak) {
                            ForEach(2...8, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Auto-inicio
                Section("Auto-inicio") {
                    Toggle("Iniciar descansos automáticamente", isOn: $settings.autoStartBreaks)
                    Toggle("Iniciar trabajo automáticamente", isOn: $settings.autoStartWork)
                }
                
                // Notificaciones
                Section("Notificaciones y Sonidos") {
                    Toggle("Habilitar notificaciones", isOn: $settings.notificationsEnabled)
                    Toggle("Sonidos de notificación", isOn: $settings.soundEnabled)
                }
                
                // Estado general
                Section("General") {
                    Toggle("Habilitar Pomodoro", isOn: $settings.isEnabled)
                }
                
                // Información
                Section(footer: footerText) {
                    EmptyView()
                }
            }
            .navigationTitle("Configuración Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
                }
            }
        }
    }
    
    private var footerText: some View {
        Text("La técnica Pomodoro te ayuda a mantener el enfoque trabajando en bloques de tiempo con descansos regulares. Ajusta las duraciones según tu preferencia personal.")
            .font(.caption)
            .foregroundStyle(themeManager.themeColors.secondary)
    }
    
    private func saveSettings() {
        pomodoroManager.updateSettings(settings)
        HapticManager.shared.success()
        dismiss()
    }
}

struct DurationSettingRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var duration: TimeInterval
    @StateObject private var themeManager = ThemeManager.shared
    
    private var durationInMinutes: Int {
        Int(duration / 60)
    }
    
    private func decreaseDuration() {
        let currentMinutes = Int(duration / 60)
        if currentMinutes > 1 {
            duration = TimeInterval((currentMinutes - 1) * 60)
            HapticManager.shared.lightImpact()
        }
    }
    
    private func increaseDuration() {
        let currentMinutes = Int(duration / 60)
        if currentMinutes < 120 {
            duration = TimeInterval((currentMinutes + 1) * 60)
            HapticManager.shared.lightImpact()
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("-") {
                    decreaseDuration()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(durationInMinutes <= 1)
                
                Text("\(durationInMinutes) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 60)
                
                Button("+") {
                    increaseDuration()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(durationInMinutes >= 120)
            }
        }
    }
}

#Preview {
    PomodoroSettingsView()
}
