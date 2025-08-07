import SwiftUI

struct PomodoroTimerView: View {
    @StateObject private var pomodoroManager = PomodoroManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingSettings = false
    @State private var showingTaskSelector = false
    @State private var selectedTask: TaskItem?
    @EnvironmentObject var choreModel: ChoreModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header with stats
                        headerSection
                        
                        // Main timer circle
                        timerCircleSection
                        
                        // Control buttons
                        controlButtonsSection
                        
                        // Session type selector
                        if pomodoroManager.timerState == .idle {
                            sessionTypeSelectorSection
                        }
                        
                        // Current task info
                        if let taskId = pomodoroManager.currentTaskId,
                           let task = choreModel.tasks.first(where: { $0.id == taskId }) {
                            currentTaskSection(task: task)
                        }
                        
                        // Today's progress
                        todayProgressSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Configuración") {
                        showingSettings = true
                        HapticManager.shared.lightImpact()
                    }
                    .foregroundStyle(themeManager.currentAccentColor)
                }
            }
            .sheet(isPresented: $showingSettings) {
                PomodoroSettingsView()
            }
            .sheet(isPresented: $showingTaskSelector) {
                TaskSelectorView(selectedTask: $selectedTask) {
                    if let task = selectedTask {
                        startPomodoroForTask(task)
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                themeManager.themeColors.background,
                themeManager.currentAccentColor.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sesiones Hoy")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Text("\(pomodoroManager.sessionsCompletedToday)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentAccentColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tiempo Enfocado")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Text(formatTime(pomodoroManager.focusTimeToday))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentAccentColor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Timer Circle Section
    private var timerCircleSection: some View {
        VStack(spacing: 24) {
            // Main timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: pomodoroManager.progress)
                    .stroke(
                        getCurrentSessionColor(),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: pomodoroManager.progress)
                
                // Inner content
                VStack(spacing: 16) {
                    // Session type icon
                    if let session = pomodoroManager.currentSession {
                        Image(systemName: session.type.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(getCurrentSessionColor())
                    }
                    
                    // Time display
                    Text(pomodoroManager.formattedTimeRemaining)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    // Session description
                    Text(pomodoroManager.currentSessionDescription)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
            }
            
            // Session completion message
            if pomodoroManager.timerState == .completed {
                completionMessage
            }
        }
    }
    
    private var completionMessage: some View {
        VStack(spacing: 12) {
            Text("🎉")
                .font(.system(size: 40))
            
            Text("¡Sesión Completada!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(themeManager.currentAccentColor)
            
            Text(getCompletionMessage())
                .font(.subheadline)
                .foregroundStyle(themeManager.themeColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentAccentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.currentAccentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Control Buttons Section
    private var controlButtonsSection: some View {
        HStack(spacing: 20) {
            // Secondary action button (left)
            secondaryActionButton
            
            // Primary action button (center)
            primaryActionButton
            
            // Stop button (right)
            if pomodoroManager.timerState != .idle {
                stopButton
            }
        }
    }
    
    private var primaryActionButton: some View {
        Button(action: primaryAction) {
            ZStack {
                Circle()
                    .fill(getCurrentSessionColor())
                    .frame(width: 80, height: 80)
                
                Image(systemName: primaryActionIcon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(pomodoroManager.timerState == .running ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pomodoroManager.timerState)
    }
    
    private var secondaryActionButton: some View {
        Button(action: secondaryAction) {
            ZStack {
                Circle()
                    .fill(themeManager.themeColors.surface)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(themeManager.themeColors.border, lineWidth: 1)
                    )
                
                Image(systemName: secondaryActionIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(themeManager.themeColors.primary)
            }
        }
    }
    
    private var stopButton: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            pomodoroManager.stopTimer()
        }) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "stop.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: - Session Type Selector
    private var sessionTypeSelectorSection: some View {
        VStack(spacing: 16) {
            Text("Seleccionar Sesión")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            HStack(spacing: 12) {
                ForEach(PomodoroSessionType.allCases, id: \.self) { sessionType in
                    SessionTypeCard(
                        type: sessionType,
                        isSelected: false
                    ) {
                        startSession(type: sessionType)
                    }
                }
            }
            
            // Quick start with task button
            Button(action: {
                showingTaskSelector = true
                HapticManager.shared.lightImpact()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                    Text("Iniciar con Tarea")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(themeManager.currentAccentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeManager.currentAccentColor.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(themeManager.currentAccentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Current Task Section
    private func currentTaskSection(task: TaskItem) -> some View {
        VStack(spacing: 12) {
            Text("Trabajando en:")
                .font(.caption)
                .foregroundStyle(themeManager.themeColors.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentAccentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    if let category = choreModel.getCategoryForTask(task) {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Today Progress Section
    private var todayProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progreso de Hoy")
                    .font(.headline)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
                
                NavigationLink("Ver Todo") {
                    PomodoroStatsView()
                }
                .font(.caption)
                .foregroundStyle(themeManager.currentAccentColor)
            }
            
            // Mini session indicators
            let todaySessions = pomodoroManager.todaySessions.prefix(8)
            HStack(spacing: 8) {
                ForEach(Array(todaySessions.enumerated()), id: \.offset) { index, session in
                    Circle()
                        .fill(session.type.color)
                        .frame(width: 12, height: 12)
                }
                
                // Empty slots
                ForEach(todaySessions.count..<8, id: \.self) { _ in
                    Circle()
                        .fill(themeManager.themeColors.surface)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
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
    }
    
    // MARK: - Actions
    private func primaryAction() {
        switch pomodoroManager.timerState {
        case .idle:
            startSession(type: .work)
        case .running:
            pomodoroManager.pauseTimer()
        case .paused:
            pomodoroManager.resumeTimer()
        case .completed:
            pomodoroManager.timerState = .idle
        }
    }
    
    private func secondaryAction() {
        switch pomodoroManager.timerState {
        case .idle:
            showingTaskSelector = true
        case .running, .paused:
            pomodoroManager.skipTimer()
        case .completed:
            startNextSession()
        }
        HapticManager.shared.lightImpact()
    }
    
    private func startSession(type: PomodoroSessionType) {
        pomodoroManager.startTimer(for: type, taskId: selectedTask?.id)
        HapticManager.shared.mediumImpact()
    }
    
    private func startPomodoroForTask(_ task: TaskItem) {
        selectedTask = task
        pomodoroManager.startTimer(for: .work, taskId: task.id)
        showingTaskSelector = false
    }
    
    private func startNextSession() {
        // Logic to determine next session type
        startSession(type: .work)
    }
    
    // MARK: - Computed Properties
    private var primaryActionIcon: String {
        switch pomodoroManager.timerState {
        case .idle, .completed: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        }
    }
    
    private var secondaryActionIcon: String {
        switch pomodoroManager.timerState {
        case .idle: return "list.bullet"
        case .running, .paused: return "forward.fill"
        case .completed: return "arrow.clockwise"
        }
    }
    
    private func getCurrentSessionColor() -> Color {
        pomodoroManager.currentSession?.type.color ?? themeManager.currentAccentColor
    }
    
    private func getCompletionMessage() -> String {
        guard let session = pomodoroManager.currentSession else { return "" }
        
        switch session.type {
        case .work:
            return "¡Excelente trabajo! Es hora de tomar un descanso bien merecido."
        case .shortBreak:
            return "Descanso completado. ¿Listo para otra sesión productiva?"
        case .longBreak:
            return "Gran descanso. Has hecho un excelente progreso hoy."
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Session Type Card
struct SessionTypeCard: View {
    let type: PomodoroSessionType
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(type.color)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text("\(Int(type.duration / 60))m")
                    .font(.caption2)
                    .foregroundStyle(themeManager.themeColors.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(type.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        PomodoroTimerView()
            .environmentObject(ChoreModel())
    }
}