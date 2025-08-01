import Foundation
import Speech
import AVFoundation
import SwiftUI

/// Manager para el reconocimiento de voz y creación de tareas por dictado
@MainActor
class SpeechRecognitionManager: ObservableObject {
    static let shared = SpeechRecognitionManager()
    
    @Published var isRecording = false
    @Published var speechText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var processingResult: TaskCreationResult?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestPermissions() async {
        // Request speech recognition permission
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume()
                }
            }
        }
        
        // Request microphone permission
        await AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.errorMessage = "Se necesita acceso al micrófono para usar esta función"
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    var isAuthorized: Bool {
        return authorizationStatus == .authorized && speechRecognizer?.isAvailable == true
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard isAuthorized else {
            errorMessage = "No se tienen los permisos necesarios para el reconocimiento de voz"
            return
        }
        
        guard !audioEngine.isRunning else {
            stopRecording()
            return
        }
        
        do {
            try startSpeechRecognition()
            isRecording = true
            speechText = ""
            errorMessage = nil
            HapticManager.shared.mediumImpact()
        } catch {
            errorMessage = "Error al iniciar el reconocimiento: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        // Set recording state to false immediately
        isRecording = false
        
        // Process any captured speech before stopping
        if !speechText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            processSpokenText(speechText)
        }
        
        // Stop audio engine first if it's running
        if audioEngine.isRunning {
            audioEngine.stop()
            // Remove tap before stopping to prevent conflicts
            if audioEngine.inputNode.numberOfOutputs > 0 {
                audioEngine.inputNode.removeTap(onBus: 0)
            }
        }
        
        // End the recognition request
        recognitionRequest?.endAudio()
        
        // Cancel the recognition task
        if let task = recognitionTask {
            task.cancel()
        }
        
        // Clean up references
        recognitionRequest = nil
        recognitionTask = nil
        
        // Reset audio session with proper error handling
        DispatchQueue.global(qos: .background).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                // Log error but don't show to user as it's a cleanup error
                print("Audio session cleanup error: \(error)")
            }
        }
        
        HapticManager.shared.lightImpact()
    }
    
    private func startSpeechRecognition() throws {
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.speechText = result.bestTranscription.formattedString
                    
                    // If result is final, process the task
                    if result.isFinal {
                        self?.stopRecording()
                        self?.processSpokenText(result.bestTranscription.formattedString)
                    }
                }
                
                if let error = error {
                    let nsError = error as NSError
                    
                    // Filter out error 216 (kAFAssistantErrorDomain) and other harmless cleanup errors
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        // This is a harmless cleanup error, just stop recording silently
                        self?.stopRecording()
                        return
                    }
                    
                    // Also filter out other common cleanup errors
                    if nsError.localizedDescription.contains("The operation couldn't be completed") ||
                       nsError.localizedDescription.contains("invalidated") ||
                       nsError.code == 203 { // Another common speech recognition cleanup error
                        self?.stopRecording()
                        return
                    }
                    
                    // Only show meaningful errors to the user
                    self?.errorMessage = "Error de reconocimiento: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
    }
    
    // MARK: - Text Processing
    
    private func processSpokenText(_ text: String) {
        let processor = TaskTextProcessor()
        processingResult = processor.processSpokenText(text)
        
        // Add haptic feedback based on result
        if processingResult?.isValid == true {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }
    }
    
    // MARK: - Task Creation
    
    func createTaskFromResult(_ result: TaskCreationResult, model: ChoreModel) {
        guard result.isValid else { return }
        
        let task = TaskItem(
            title: result.title,
            categoryId: result.categoryId,
            hasReminder: result.hasReminder,
            reminderTime: result.reminderTime,
            repeatDaily: result.repeatDaily,
            specificDate: result.specificDate,
            taskType: result.taskType
        )
        
        model.tasks.append(task)
        model.saveTasks()
        
        // Schedule notification if needed
        if result.hasReminder, let reminderTime = result.reminderTime {
            NotificationService.shared.scheduleTaskReminder(
                for: task,
                at: reminderTime,
                repeatDaily: result.repeatDaily
            )
        }
        
        HapticManager.shared.taskCreated()
        
        // Clear processing result after successful creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.processingResult = nil
            self.speechText = ""
        }
    }
    
    // MARK: - Cleanup
    
    func reset() {
        stopRecording()
        speechText = ""
        errorMessage = nil
        processingResult = nil
    }
}

// MARK: - Speech Error Types

enum SpeechError: Error, LocalizedError {
    case recognitionRequestFailed
    case audioEngineFailed
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "No se pudo crear la solicitud de reconocimiento"
        case .audioEngineFailed:
            return "Error al configurar el audio"
        case .recognitionFailed:
            return "Error en el reconocimiento de voz"
        }
    }
}

// MARK: - Task Creation Result

struct TaskCreationResult {
    let title: String
    let categoryId: UUID?
    let hasReminder: Bool
    let reminderTime: Date?
    let repeatDaily: Bool
    let specificDate: Date?
    let taskType: TaskItem.TaskType
    let confidence: Float
    let originalText: String
    
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && confidence > 0.3
    }
}

// MARK: - Task Text Processor

class TaskTextProcessor {
    private let calendar = Calendar.current
    
    func processSpokenText(_ text: String) -> TaskCreationResult {
        let lowercasedText = text.lowercased()
        
        // Extract task title (main content)
        let title = extractTaskTitle(from: text)
        
        // Extract date information
        let (specificDate, taskType) = extractDateInfo(from: lowercasedText)
        
        // Extract time information for reminders
        let (hasReminder, reminderTime) = extractTimeInfo(from: lowercasedText, specificDate: specificDate)
        
        // Extract repetition info
        let repeatDaily = extractRepetitionInfo(from: lowercasedText)
        
        // Calculate confidence based on clarity of extraction
        let confidence = calculateConfidence(
            title: title,
            hasDateInfo: specificDate != nil,
            hasTimeInfo: hasReminder
        )
        
        return TaskCreationResult(
            title: title,
            categoryId: nil, // Could be enhanced to detect categories from text
            hasReminder: hasReminder,
            reminderTime: reminderTime,
            repeatDaily: repeatDaily,
            specificDate: specificDate,
            taskType: taskType,
            confidence: confidence,
            originalText: text
        )
    }
    
    private func extractTaskTitle(from text: String) -> String {
        // Remove common prefixes and suffixes for task creation
        let prefixesToRemove = [
            "recordarme",
            "recuérdame",
            "agregar",
            "añadir",
            "crear",
            "nueva tarea",
            "tarea",
            "tengo que",
            "debo",
            "necesito"
        ]
        
        let suffixesToRemove = [
            "por favor",
            "gracias"
        ]
        
        var cleanedText = text.lowercased()
        
        // Remove prefixes
        for prefix in prefixesToRemove {
            if cleanedText.hasPrefix(prefix) {
                cleanedText = String(cleanedText.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Remove suffixes
        for suffix in suffixesToRemove {
            if cleanedText.hasSuffix(suffix) {
                cleanedText = String(cleanedText.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove time and date references to clean up the title
        let timePatterns = [
            "mañana", "tarde", "noche", "hoy", "después",
            "a las \\d+", "\\d+ de la mañana", "\\d+ de la tarde"
        ]
        
        for pattern in timePatterns {
            cleanedText = cleanedText.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            ).trimmingCharacters(in: .whitespaces)
        }
        
        return cleanedText.capitalized
    }
    
    private func extractDateInfo(from text: String) -> (Date?, TaskItem.TaskType) {
        let today = Date()
        
        // Check for "hoy" first - should be highest priority
        if text.contains("hoy") {
            return (today, .specific)
        }
        
        // Check for "mañana"
        if text.contains("mañana") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
            return (tomorrow, .specific)
        }
        
        // Check for parts of today
        if text.contains("esta mañana") || text.contains("esta tarde") || text.contains("esta noche") {
            return (today, .specific)
        }
        
        // Check for "ahora" or "ahorita"
        if text.contains("ahora") || text.contains("ahorita") {
            return (today, .specific)
        }
        
        // Check for specific days of the week
        let dayPatterns = [
            ("lunes", 2), ("martes", 3), ("miércoles", 4), ("jueves", 5),
            ("viernes", 6), ("sábado", 7), ("domingo", 1)
        ]
        
        for (dayName, weekday) in dayPatterns {
            if text.contains(dayName) {
                // If it's the same day as today, return today instead of next week
                let todayWeekday = calendar.component(.weekday, from: today)
                if todayWeekday == weekday {
                    return (today, .specific)
                }
                
                if let nextDate = calendar.nextDate(
                    after: today,
                    matching: DateComponents(weekday: weekday),
                    matchingPolicy: .nextTime
                ) {
                    return (nextDate, .specific)
                }
            }
        }
        
        // Default to daily task if no specific date mentioned
        return (nil, .daily)
    }
    
    private func extractTimeInfo(from text: String, specificDate: Date?) -> (Bool, Date?) {
        let timePatterns = [
            ("a las (\\d+)", "hour"),
            ("(\\d+) de la mañana", "morning"),
            ("(\\d+) de la tarde", "afternoon"),
            ("(\\d+) de la noche", "night")
        ]
        
        for (pattern, timeType) in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let hourRange = Range(match.range(at: 1), in: text) {
                
                if let hour = Int(String(text[hourRange])) {
                    let adjustedHour = adjustHour(hour, for: timeType)
                    
                    let targetDate = specificDate ?? Date()
                    let reminderTime = calendar.date(
                        bySettingHour: adjustedHour,
                        minute: 0,
                        second: 0,
                        of: targetDate
                    )
                    return (true, reminderTime)
                }
            }
        }
        
        return (false, nil)
    }
    
    private func adjustHour(_ hour: Int, for timeType: String) -> Int {
        switch timeType {
        case "morning":
            return hour < 12 ? hour : hour
        case "afternoon":
            return hour < 12 ? hour + 12 : hour
        case "night":
            return hour < 12 ? hour + 12 : hour
        default:
            return hour
        }
    }
    
    private func extractRepetitionInfo(from text: String) -> Bool {
        let repetitionKeywords = ["diario", "diariamente", "todos los días", "cada día"]
        return repetitionKeywords.contains { text.contains($0) }
    }
    
    private func calculateConfidence(title: String, hasDateInfo: Bool, hasTimeInfo: Bool) -> Float {
        var confidence: Float = 0.5 // Base confidence
        
        if !title.isEmpty {
            confidence += 0.3
        }
        
        if hasDateInfo {
            confidence += 0.1
        }
        
        if hasTimeInfo {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
}
