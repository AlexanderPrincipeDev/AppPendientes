import SwiftUI

struct VoiceTaskCreationView: View {
    @StateObject private var speechManager = SpeechRecognitionManager.shared
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPermissionAlert = false
    @State private var hasRequestedPermissions = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentAccentColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(themeManager.currentAccentColor)
                    }
                    
                    Text("Crear Tarea por Voz")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text("Dime qué tarea quieres agregar")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.themeColors.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Voice Recording Section
                VStack(spacing: 20) {
                    // Recording Button
                    Button(action: handleRecordingAction) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? .red : themeManager.currentAccentColor)
                                .frame(width: 120, height: 120)
                                .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechManager.isRecording)
                            
                            Circle()
                                .stroke(speechManager.isRecording ? .red.opacity(0.3) : themeManager.currentAccentColor.opacity(0.3), lineWidth: 4)
                                .frame(width: 140, height: 140)
                                .scaleEffect(speechManager.isRecording ? 1.2 : 1.0)
                                .opacity(speechManager.isRecording ? 0.6 : 0.3)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechManager.isRecording)
                            
                            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(!speechManager.isAuthorized)
                    .buttonStyle(.plain)
                    
                    // Status Text
                    VStack(spacing: 8) {
                        Text(recordingStatusText)
                            .font(.headline)
                            .foregroundStyle(speechManager.isRecording ? .red : themeManager.themeColors.primary)
                            .animation(.easeInOut(duration: 0.3), value: speechManager.isRecording)
                        
                        if speechManager.isRecording {
                            Text("Habla ahora...")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.themeColors.secondary)
                        }
                    }
                }
                
                // Speech Text Display
                if !speechManager.speechText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Texto reconocido:")
                            .font(.headline)
                            .foregroundStyle(themeManager.themeColors.primary)
                        
                        ScrollView {
                            Text(speechManager.speechText)
                                .font(.body)
                                .foregroundStyle(themeManager.themeColors.primary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.themeColors.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.themeColors.border, lineWidth: 1)
                                        )
                                )
                        }
                        .frame(maxHeight: 100)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
                
                // Processing Result
                if let result = speechManager.processingResult {
                    TaskProcessingResultView(result: result)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Ejemplos de comandos:")
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    VStack(spacing: 8) {
                        ExampleCommand(text: "\"Recordarme comprar leche mañana a las 3\"")
                        ExampleCommand(text: "\"Hacer ejercicio hoy a las 7 de la mañana\"")
                        ExampleCommand(text: "\"Llamar al médico\"")
                        ExampleCommand(text: "\"Estudiar para el examen el viernes\"")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.themeColors.background)
            .navigationTitle("Voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        speechManager.reset()
                        dismiss()
                    }
                    .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                if speechManager.processingResult?.isValid == true {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Crear Tarea") {
                            createTaskFromResult()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.currentAccentColor)
                    }
                }
            }
        }
        .onAppear {
            checkPermissions()
        }
        .alert("Permisos Necesarios", isPresented: $showingPermissionAlert) {
            Button("Configuración") {
                openSettings()
            }
            Button("Cancelar", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Para usar el reconocimiento de voz necesitas habilitar los permisos de micrófono y reconocimiento de voz en Configuración.")
        }
        .alert("Error", isPresented: .constant(speechManager.errorMessage != nil)) {
            Button("OK") {
                speechManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = speechManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var recordingStatusText: String {
        if !speechManager.isAuthorized {
            return "Permisos requeridos"
        } else if speechManager.isRecording {
            return "Escuchando..."
        } else {
            return "Toca para hablar"
        }
    }
    
    private func handleRecordingAction() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            speechManager.startRecording()
        }
    }
    
    private func checkPermissions() {
        if !hasRequestedPermissions {
            hasRequestedPermissions = true
            Task {
                await speechManager.requestPermissions()
                if !speechManager.isAuthorized {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    private func createTaskFromResult() {
        guard let result = speechManager.processingResult else { return }
        speechManager.createTaskFromResult(result, model: model)
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Task Processing Result View
struct TaskProcessingResultView: View {
    let result: TaskCreationResult
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(result.isValid ? themeManager.themeColors.success : themeManager.themeColors.warning)
                
                Text(result.isValid ? "Tarea Procesada" : "Revisar Información")
                    .font(.headline)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            // Task Details
            VStack(spacing: 12) {
                TaskDetailRow(
                    icon: "textformat",
                    label: "Título",
                    value: result.title,
                    isValid: !result.title.isEmpty
                )
                
                if result.hasReminder {
                    TaskDetailRow(
                        icon: "clock",
                        label: "Recordatorio",
                        value: result.reminderTime?.formatted(date: .omitted, time: .shortened) ?? "Sin hora específica",
                        isValid: result.reminderTime != nil
                    )
                }
                
                if let specificDate = result.specificDate {
                    TaskDetailRow(
                        icon: "calendar",
                        label: "Fecha",
                        value: specificDate.formatted(date: .abbreviated, time: .omitted),
                        isValid: true
                    )
                }
                
                if result.repeatDaily {
                    TaskDetailRow(
                        icon: "repeat",
                        label: "Repetición",
                        value: "Diaria",
                        isValid: true
                    )
                }
                
                TaskDetailRow(
                    icon: "folder",
                    label: "Categoría",
                    value: getCategoryName(for: result.categoryId),
                    isValid: true
                )
                
                // Confidence indicator
                HStack {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Text("Confianza: \(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(result.isValid ? themeManager.themeColors.success.opacity(0.3) : themeManager.themeColors.warning.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private func getCategoryName(for categoryId: UUID?) -> String {
        guard let categoryId = categoryId else { return "General" }
        
        // Buscar la categoría en las categorías por defecto
        if let category = TaskCategory.defaultCategories.first(where: { $0.id == categoryId }) {
            return category.name
        }
        
        return "General"
    }
}

// MARK: - Task Detail Row
struct TaskDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let isValid: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(isValid ? themeManager.currentAccentColor : themeManager.themeColors.secondary)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(themeManager.themeColors.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isValid ? themeManager.themeColors.primary : themeManager.themeColors.secondary)
                .lineLimit(1)
            
            Spacer()
            
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(themeManager.themeColors.success)
            }
        }
    }
}

// MARK: - Example Command
struct ExampleCommand: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: "quote.bubble")
                .font(.caption2)
                .foregroundStyle(themeManager.currentAccentColor)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(themeManager.themeColors.secondary)
                .italic()
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentAccentColor.opacity(0.1))
        )
    }
}

#Preview {
    VoiceTaskCreationView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(ChoreModel())
}
