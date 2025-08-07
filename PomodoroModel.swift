import SwiftUI
import Foundation

// MARK: - Pomodoro Session Model
struct PomodoroSession: Identifiable, Codable {
    let id = UUID()
    let taskId: UUID?
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let type: PomodoroSessionType
    let isCompleted: Bool
    let notes: String?
    
    init(taskId: UUID? = nil, duration: TimeInterval, type: PomodoroSessionType) {
        self.taskId = taskId
        self.startTime = Date()
        self.endTime = nil
        self.duration = duration
        self.type = type
        self.isCompleted = false
        self.notes = nil
    }
}

// MARK: - Session Types
enum PomodoroSessionType: String, CaseIterable, Codable {
    case work = "Trabajo"
    case shortBreak = "Descanso Corto"
    case longBreak = "Descanso Largo"
    
    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60 // 25 minutos
        case .shortBreak: return 5 * 60 // 5 minutos
        case .longBreak: return 15 * 60 // 15 minutos
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
}

// MARK: - Pomodoro Settings
struct PomodoroSettings: Codable {
    var workDuration: TimeInterval = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval = 15 * 60
    var sessionsUntilLongBreak: Int = 4
    var autoStartBreaks: Bool = false
    var autoStartWork: Bool = false
    var soundEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var isEnabled: Bool = true
}

// MARK: - Pomodoro Timer State
enum PomodoroTimerState {
    case idle
    case running
    case paused
    case completed
}

// MARK: - Pomodoro Manager
class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()
    
    @Published var currentSession: PomodoroSession?
    @Published var timerState: PomodoroTimerState = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var sessions: [PomodoroSession] = []
    @Published var settings: PomodoroSettings = PomodoroSettings()
    @Published var currentTaskId: UUID?
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "pomodoroSessions"
    private let settingsKey = "pomodoroSettings"
    
    // Estadísticas
    @Published var todaySessions: [PomodoroSession] = []
    @Published var weekSessions: [PomodoroSession] = []
    @Published var totalFocusTime: TimeInterval = 0
    
    private init() {
        loadSettings()
        loadSessions()
        updateStatistics()
    }
    
    // MARK: - Timer Control
    func startTimer(for type: PomodoroSessionType, taskId: UUID? = nil) {
        // Si hay un timer corriendo, lo pausamos
        if timerState == .running {
            pauseTimer()
        }
        
        // Crear nueva sesión
        currentSession = PomodoroSession(
            taskId: taskId,
            duration: getDuration(for: type),
            type: type
        )
        
        currentTaskId = taskId
        timeRemaining = getDuration(for: type)
        timerState = .running
        
        // Iniciar timer
        startInternalTimer()
        
        // Haptic feedback
        HapticManager.shared.mediumImpact()
        
        // Notificación local
        if settings.notificationsEnabled {
            scheduleNotification()
        }
    }
    
    func pauseTimer() {
        guard timerState == .running else { return }
        
        timer?.invalidate()
        timerState = .paused
        HapticManager.shared.lightImpact()
    }
    
    func resumeTimer() {
        guard timerState == .paused else { return }
        
        timerState = .running
        startInternalTimer()
        HapticManager.shared.lightImpact()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        currentSession = nil
        timeRemaining = 0
        currentTaskId = nil
        HapticManager.shared.lightImpact()
        cancelNotifications()
    }
    
    func skipTimer() {
        completeCurrentSession()
        HapticManager.shared.mediumImpact()
    }
    
    // MARK: - Private Methods
    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        guard timeRemaining > 0 else {
            completeCurrentSession()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        timerState = .completed
        
        // Guardar sesión completada
        if var session = currentSession {
            let completedSession = PomodoroSession(
                taskId: session.taskId,
                duration: session.duration,
                type: session.type
            )
            sessions.append(completedSession)
            saveSessions()
            updateStatistics()
        }
        
        // Haptic y notificación
        HapticManager.shared.success()
        
        // Auto-start next session if enabled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.shouldAutoStartNext() {
                self.startNextSession()
            } else {
                self.timerState = .idle
                self.currentSession = nil
            }
        }
    }
    
    private func startNextSession() {
        guard let currentSession = currentSession else { return }
        
        let nextType = getNextSessionType(after: currentSession.type)
        startTimer(for: nextType, taskId: currentTaskId)
    }
    
    private func getNextSessionType(after type: PomodoroSessionType) -> PomodoroSessionType {
        switch type {
        case .work:
            let workSessionsToday = todaySessions.filter { $0.type == .work }.count
            return (workSessionsToday % settings.sessionsUntilLongBreak == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
    
    private func shouldAutoStartNext() -> Bool {
        guard let currentSession = currentSession else { return false }
        
        switch currentSession.type {
        case .work:
            return settings.autoStartBreaks
        case .shortBreak, .longBreak:
            return settings.autoStartWork
        }
    }
    
    private func getDuration(for type: PomodoroSessionType) -> TimeInterval {
        switch type {
        case .work: return settings.workDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak: return settings.longBreakDuration
        }
    }
    
    // MARK: - Statistics
    private func updateStatistics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        todaySessions = sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }
        
        weekSessions = sessions.filter { session in
            session.startTime >= weekAgo
        }
        
        totalFocusTime = sessions
            .filter { $0.type == .work && $0.isCompleted }
            .reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Data Persistence
    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            settings = decoded
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            sessions = decoded
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    // MARK: - Public Interface
    func updateSettings(_ newSettings: PomodoroSettings) {
        settings = newSettings
        saveSettings()
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
        updateStatistics()
    }
    
    func getSessionsForDate(_ date: Date) -> [PomodoroSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
    
    // MARK: - Notifications
    private func scheduleNotification() {
        guard let session = currentSession else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Completado"
        content.body = getNotificationMessage(for: session.type)
        content.sound = settings.soundEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeRemaining,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "pomodoro_\(session.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func getNotificationMessage(for type: PomodoroSessionType) -> String {
        switch type {
        case .work:
            return "¡Sesión de trabajo completada! Es hora de tomar un descanso."
        case .shortBreak:
            return "Descanso terminado. ¿Listo para otra sesión de trabajo?"
        case .longBreak:
            return "Descanso largo completado. ¡Excelente trabajo hoy!"
        }
    }
}

// MARK: - Extensions
extension PomodoroManager {
    var progress: Double {
        guard let session = currentSession else { return 0 }
        let elapsed = session.duration - timeRemaining
        return elapsed / session.duration
    }
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentSessionDescription: String {
        guard let session = currentSession else { return "Sin sesión activa" }
        return session.type.rawValue
    }
    
    var sessionsCompletedToday: Int {
        todaySessions.filter { $0.isCompleted }.count
    }
    
    var focusTimeToday: TimeInterval {
        todaySessions
            .filter { $0.type == .work && $0.isCompleted }
            .reduce(0) { $0 + $1.duration }
    }
}