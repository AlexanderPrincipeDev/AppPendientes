import SwiftUI

struct HapticSettingsView: View {
    @State private var isHapticsEnabled = true
    @State private var showingHapticTest = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuración Háptica")) {
                    // Toggle principal
                    Toggle("Habilitar Retroalimentación Háptica", isOn: $isHapticsEnabled)
                        .onChange(of: isHapticsEnabled) { newValue in
                            if newValue {
                                HapticManager.shared.lightImpact()
                            }
                        }
                    
                    if isHapticsEnabled {
                        // Información sobre compatibilidad
                        Label("Los hápticos funcionan mejor en iPhone", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if isHapticsEnabled {
                    Section(header: Text("Probar Hápticos")) {
                        // Test de patrones básicos
                        hapticTestButton("Ligero", action: { HapticManager.shared.lightImpact() })
                        hapticTestButton("Medio", action: { HapticManager.shared.mediumImpact() })  
                        hapticTestButton("Fuerte", action: { HapticManager.shared.heavyImpact() })
                        
                        Divider()
                        
                        // Test de patrones de notificación
                        hapticTestButton("Éxito ✅", action: { HapticManager.shared.success() })
                        hapticTestButton("Advertencia ⚠️", action: { HapticManager.shared.warning() })
                        hapticTestButton("Error ❌", action: { HapticManager.shared.error() })
                        
                        Divider()
                        
                        // Test de patrones contextuales
                        hapticTestButton("Tarea Completada 🎯", action: { HapticManager.shared.taskCompleted() })
                        hapticTestButton("Navegación 🧭", action: { HapticManager.shared.navigation() })
                        hapticTestButton("Selección 👆", action: { HapticManager.shared.selection() })
                        hapticTestButton("Botón Presionado 🔘", action: { HapticManager.shared.buttonPress() })
                    }
                }
                
                Section(footer: footerText) {
                    // Sección vacía solo para mostrar el footer
                }
            }
            .navigationTitle("Configuración Háptica")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func hapticTestButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "hand.tap")
                    .foregroundColor(.blue)
            }
        }
        .foregroundColor(.primary)
    }
    
    private var footerText: some View {
        Text("La retroalimentación háptica mejora la experiencia de uso proporcionando respuestas táctiles a tus acciones. Los patrones están diseñados específicamente para diferentes tipos de interacciones en la app.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// MARK: - Vista de Demostración Interactiva

struct HapticDemoView: View {
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
                        HapticManager.shared.lightImpact()
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
            
            Spacer()
        }
        .padding()
        .navigationTitle("Demo Hápticos")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func completeTask() {
        completedTasks += 1
        
        // Feedback háptico basado en progreso
        if completedTasks >= totalTasks {
            // Si se completaron todas las tareas
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.success()
            }
        } else {
            // Progreso normal
            HapticManager.shared.taskCompleted()
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
