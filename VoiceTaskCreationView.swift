import SwiftUI

struct VoiceTaskCreationView: View {
    @StateObject private var speechManager = SpeechRecognitionManager.shared
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPermissionAlert = false
    @State private var hasRequestedPermissions = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 24) {
                            // Top Decoration
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(themeManager.currentAccentColor.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .fill(themeManager.currentAccentColor.opacity(0.2))
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            .padding(.top, 20)
                            
                            // Main Header
                            VStack(spacing: 16) {
                                // Animated Microphone Icon
                                ZStack {
                                    // Background gradient
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    themeManager.currentAccentColor.opacity(0.3),
                                                    themeManager.currentAccentColor.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    // Pulse effect when recording
                                    if speechManager.isRecording {
                                        Circle()
                                            .stroke(themeManager.currentAccentColor.opacity(0.3), lineWidth: 2)
                                            .frame(width: 120, height: 120)
                                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                            .opacity(pulseAnimation ? 0.0 : 0.8)
                                            .animation(
                                                .easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: false),
                                                value: pulseAnimation
                                            )
                                    }
                                    
                                    // Microphone icon
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 36, weight: .medium))
                                        .foregroundStyle(themeManager.currentAccentColor)
                                        .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: speechManager.isRecording)
                                }
                                
                                // Title and subtitle
                                VStack(spacing: 8) {
                                    Text("Asistente de Voz")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(themeManager.themeColors.primary)
                                    
                                    Text("Di tu tarea y yo la organizaré por ti")
                                        .font(.subheadline)
                                        .foregroundStyle(themeManager.themeColors.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        
                        // Recording Section
                        VStack(spacing: 32) {
                            // Recording Button with enhanced design
                            Button(action: handleRecordingAction) {
                                ZStack {
                                    // Outer glow effect
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    (speechManager.isRecording ? .red : themeManager.currentAccentColor).opacity(0.1),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 80,
                                                endRadius: 120
                                            )
                                        )
                                        .frame(width: 180, height: 180)
                                        .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechManager.isRecording)
                                    
                                    // Main button
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: speechManager.isRecording ? 
                                                    [.red, .red.opacity(0.8)] :
                                                    [themeManager.currentAccentColor, themeManager.currentAccentColor.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 140, height: 140)
                                        .shadow(
                                            color: (speechManager.isRecording ? .red : themeManager.currentAccentColor).opacity(0.3),
                                            radius: 15,
                                            x: 0,
                                            y: 8
                                        )
                                    
                                    // Icon
                                    Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .scaleEffect(speechManager.isRecording ? 0.9 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: speechManager.isRecording)
                                }
                            }
                            .disabled(!speechManager.isAuthorized)
                            .buttonStyle(.plain)
                            .scaleEffect(speechManager.isAuthorized ? 1.0 : 0.9)
                            .opacity(speechManager.isAuthorized ? 1.0 : 0.6)
                            
                            // Status Text with enhanced styling
                            VStack(spacing: 12) {
                                Text(recordingStatusText)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        speechManager.isRecording ? .red : 
                                        speechManager.isAuthorized ? themeManager.themeColors.primary : 
                                        themeManager.themeColors.secondary
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: speechManager.isRecording)
                                
                                if speechManager.isRecording {
                                    HStack(spacing: 8) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(.red)
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                                .animation(
                                                    .easeInOut(duration: 0.6)
                                                    .repeatForever()
                                                    .delay(Double(index) * 0.2),
                                                    value: pulseAnimation
                                                )
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                if !speechManager.isAuthorized {
                                    Text("Toca para configurar permisos")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.themeColors.secondary)
                                        .italic()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Content Section
                        VStack(spacing: 24) {
                            // Speech Text Display with improved design
                            if !speechManager.speechText.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "quote.opening")
                                            .font(.title3)
                                            .foregroundStyle(themeManager.currentAccentColor)
                                        
                                        Text("Lo que escuché:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(themeManager.themeColors.primary)
                                        
                                        Spacer()
                                    }
                                    
                                    Text(speechManager.speechText)
                                        .font(.body)
                                        .foregroundStyle(themeManager.themeColors.primary)
                                        .padding(20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(themeManager.themeColors.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                                                )
                                                .shadow(color: themeManager.themeColors.primary.opacity(0.05), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .padding(.horizontal, 24)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 0.9).combined(with: .opacity)
                                ))
                            }
                            
                            // Processing Result with enhanced design
                            if let result = speechManager.processingResult {
                                TaskProcessingResultView(result: result)
                                    .padding(.horizontal, 24)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    ))
                            }
                            
                            // Instructions with improved layout
                            if speechManager.processingResult == nil && speechManager.speechText.isEmpty {
                                VStack(spacing: 20) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.title3)
                                            .foregroundStyle(.yellow)
                                        
                                        Text("Ejemplos de comandos:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(themeManager.themeColors.primary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 12) {
                                        ExampleCommand(text: "Recordarme comprar leche mañana a las 3", icon: "cart.fill")
                                        ExampleCommand(text: "Hacer ejercicio hoy a las 7 de la mañana", icon: "figure.run")
                                        ExampleCommand(text: "Llamar al médico el viernes", icon: "phone.fill")
                                        ExampleCommand(text: "Estudiar para el examen", icon: "book.fill")
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        themeManager.themeColors.background,
                        themeManager.currentAccentColor.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        speechManager.reset()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                            Text("Cerrar")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(themeManager.themeColors.secondary)
                    }
                }
                
                if speechManager.processingResult?.isValid == true {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            createTaskFromResult()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Crear")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentAccentColor)
                                    .shadow(color: themeManager.currentAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            checkPermissions()
            pulseAnimation = true
        }
        .onDisappear {
            pulseAnimation = false
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
        VStack(spacing: 20) {
            // Header with improved design
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(result.isValid ? themeManager.themeColors.success.opacity(0.1) : themeManager.themeColors.warning.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(result.isValid ? themeManager.themeColors.success : themeManager.themeColors.warning)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isValid ? "✨ Tarea Lista" : "⚠️ Revisar Información")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text(result.isValid ? "Todo se ve perfecto" : "Algunos detalles necesitan atención")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                Spacer()
                
                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentAccentColor)
                    
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.currentAccentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(themeManager.currentAccentColor.opacity(0.1))
                )
            }
            
            // Task Details with card design
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // Title
                TaskDetailCard(
                    icon: "textformat",
                    label: "Título",
                    value: result.title,
                    isValid: !result.title.isEmpty,
                    accentColor: themeManager.currentAccentColor
                )
                
                // Category
                TaskDetailCard(
                    icon: "folder.fill",
                    label: "Categoría",
                    value: getCategoryName(for: result.categoryId),
                    isValid: true,
                    accentColor: themeManager.currentAccentColor
                )
                
                // Date (if exists)
                if let specificDate = result.specificDate {
                    TaskDetailCard(
                        icon: "calendar",
                        label: "Fecha",
                        value: specificDate.formatted(date: .abbreviated, time: .omitted),
                        isValid: true,
                        accentColor: themeManager.currentAccentColor
                    )
                }
                
                // Reminder (if exists)
                if result.hasReminder {
                    TaskDetailCard(
                        icon: "clock.fill",
                        label: "Recordatorio",
                        value: result.reminderTime?.formatted(date: .omitted, time: .shortened) ?? "10:00 AM",
                        isValid: result.reminderTime != nil,
                        accentColor: themeManager.currentAccentColor
                    )
                }
                
                // Repeat (if daily)
                if result.repeatDaily {
                    TaskDetailCard(
                        icon: "repeat",
                        label: "Repetición",
                        value: "Diaria",
                        isValid: true,
                        accentColor: themeManager.currentAccentColor
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.themeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            result.isValid ? 
                                themeManager.themeColors.success.opacity(0.2) : 
                                themeManager.themeColors.warning.opacity(0.2), 
                            lineWidth: 1
                        )
                )
                .shadow(color: themeManager.themeColors.primary.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
    
    private func getCategoryName(for categoryId: UUID?) -> String {
        guard let categoryId = categoryId else { return "General" }
        
        if let category = TaskCategory.defaultCategories.first(where: { $0.id == categoryId }) {
            return category.name
        }
        
        return "General"
    }
}

// MARK: - Task Detail Card
struct TaskDetailCard: View {
    let icon: String
    let label: String
    let value: String
    let isValid: Bool
    let accentColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(isValid ? accentColor : themeManager.themeColors.secondary)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.themeColors.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(themeManager.themeColors.success)
                }
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isValid ? themeManager.themeColors.primary : themeManager.themeColors.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeColors.background.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.themeColors.border.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Example Command
struct ExampleCommand: View {
    let text: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeManager.currentAccentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(themeManager.themeColors.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.themeColors.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.currentAccentColor.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: themeManager.themeColors.primary.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

#Preview {
    VoiceTaskCreationView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(ChoreModel())
}
