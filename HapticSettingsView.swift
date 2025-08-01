import SwiftUI

struct HapticSettingsView: View {
    @StateObject private var hapticManager = HapticManager.shared
    @State private var showingHapticTest = false
    
    var body: some View {
        Form {
            Section(header: Text("Configuración Háptica")) {
                // Toggle principal
                Toggle("Habilitar Retroalimentación Háptica", isOn: $hapticManager.isHapticsEnabled)
                    .onChange(of: hapticManager.isHapticsEnabled) { newValue in
                        if newValue {
                            hapticManager.lightImpact()
                        }
                    }
                
                if hapticManager.isHapticsEnabled {
                    // Control de intensidad
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensidad")
                            Spacer()
                            Text("\(Int(hapticManager.hapticsIntensity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $hapticManager.hapticsIntensity,
                            in: 0.1...1.0,
                            step: 0.1
                        ) {
                            Text("Intensidad Háptica")
                        } onEditingChanged: { editing in
                            if !editing {
                                hapticManager.mediumImpact()
                            }
                        }
                    }
                    
                    // Información sobre compatibilidad
                    if !hapticManager.deviceSupportsHaptics() {
                        Label("Los hápticos funcionan mejor en iPhone", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if hapticManager.isHapticsEnabled {
                Section(header: Text("Probar Hápticos")) {
                    // Test de patrones básicos
                    hapticTestButton("Ligero", pattern: .light)
                    hapticTestButton("Medio", pattern: .medium)  
                    hapticTestButton("Fuerte", pattern: .heavy)
                    
                    Divider()
                    
                    // Test de patrones de notificación
                    hapticTestButton("Éxito ✅", pattern: .success)
                    hapticTestButton("Advertencia ⚠️", pattern: .warning)
                    hapticTestButton("Error ❌", pattern: .error)
                    
                    Divider()
                    
                    // Test de patrones especiales
                    hapticTestButton("Tarea Completada 🎯", pattern: .taskCompletion)
                    hapticTestButton("¡Logro Desbloqueado! 🏆", pattern: .achievement)
                    hapticTestButton("¡Día Completado! 🎉", pattern: .celebration)
                    hapticTestButton("Heartbeat 💓", pattern: .heartbeat)
                }
            }
            
            Section(footer: footerText) {
                // Sección vacía solo para mostrar el footer
            }
        }
        .navigationTitle("Configuración Háptica")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func hapticTestButton(_ title: String, pattern: HapticTestPattern) -> some View {
        Button(action: {
            triggerTestPattern(pattern)
        }) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "hand.tap")
                    .foregroundColor(.blue)
            }
        }
        .foregroundColor(.primary)
    }
    
    private func triggerTestPattern(_ pattern: HapticTestPattern) {
        switch pattern {
        case .light:
            hapticManager.lightImpact()
        case .medium:
            hapticManager.mediumImpact()
        case .heavy:
            hapticManager.heavyImpact()
        case .success:
            hapticManager.success()
        case .warning:
            hapticManager.warning()
        case .error:
            hapticManager.error()
        case .taskCompletion:
            hapticManager.taskCompleted()
        case .achievement:
            hapticManager.achievementUnlocked()
        case .celebration:
            hapticManager.allTasksCompleted()
        case .heartbeat:
            hapticManager.heartbeatPattern()
        }
    }
    
    private var footerText: some View {
        Text("La retroalimentación háptica mejora la experiencia de uso proporcionando respuestas táctiles a tus acciones. Los patrones están diseñados específicamente para diferentes tipos de interacciones en la app.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

enum HapticTestPattern {
    case light, medium, heavy
    case success, warning, error
    case taskCompletion, achievement, celebration, heartbeat
}

// MARK: - Vista de Demostración Interactiva

struct HapticDemoView: View {
    @ObservedObject private var hapticManager = HapticManager.shared
    @State private var completedTasks = 0
    @State private var totalTasks = 5
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Demo Interactiva de Hápticos")
                .font(.title2)
                .fontWeight(.bold)
            
            // Simulador de tareas
            VStack(spacing: 15) {
                Text("Simular Completar Tareas")
                    .font(.headline)
                
                HStack {
                    Text("Progreso: \(completedTasks)/\(totalTasks)")
                    Spacer()
                    Button("Reset") {
                        completedTasks = 0
                        hapticManager.lightImpact()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Button(action: completeTask) {
                    Text(completedTasks >= totalTasks ? "¡Todas Completadas!" : "Completar Tarea")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(completedTasks >= totalTasks)
                
                if completedTasks >= totalTasks {
                    Text("🎉 ¡Felicitaciones! 🎉")
                        .font(.headline)
                        .foregroundColor(.green)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: completedTasks)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
            
            // Simulador de voz
            VStack(spacing: 15) {
                Text("Simular Grabación de Voz")
                    .font(.headline)
                
                Button("Iniciar Grabación") {
                    hapticManager.voiceRecordingStarted()
                }
                .buttonStyle(.bordered)
                
                Button("Detener Grabación") {
                    hapticManager.voiceRecordingStopped()
                }
                .buttonStyle(.bordered)
                
                HStack(spacing: 20) {
                    Button("Éxito 🎯") {
                        hapticManager.voiceRecognitionSuccess()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Error ❌") {
                        hapticManager.voiceRecognitionFailed()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Demo Hápticos")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func completeTask() {
        completedTasks += 1
        
        // Patrón de progreso
        hapticManager.progressPattern(progress: Float(completedTasks) / Float(totalTasks))
        
        // Si se completaron todas las tareas
        if completedTasks >= totalTasks {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hapticManager.allTasksCompleted()
            }
        }
    }
}

#Preview {
    NavigationView {
        HapticSettingsView()
    }
}

#Preview("Demo") {
    NavigationView {
        HapticDemoView()
    }
}
