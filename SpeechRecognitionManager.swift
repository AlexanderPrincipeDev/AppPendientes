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
        
        // Debug: Print detected date info
        if let date = specificDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "es-ES")
            print("🗓️ Fecha detectada: \(formatter.string(from: date)) para texto: '\(text)'")
        } else {
            print("🗓️ No se detectó fecha específica para: '\(text)' - Será tarea diaria")
        }
        
        // Extract category information based on task content
        let detectedCategory = extractCategoryInfo(from: lowercasedText)
        
        // Debug: Print detected category info
        if let categoryId = detectedCategory?.id {
            print("🏷️ Categoría detectada: \(categoryId) para texto: '\(text)'")
        } else {
            print("🏷️ No se detectó categoría para texto: '\(text)'")
        }
        
        // Extract time information for reminders
        let (hasReminder, reminderTime) = extractTimeInfo(from: lowercasedText, specificDate: specificDate)
        
        // Debug: Print reminder detection info
        if hasReminder {
            if let reminderTime = reminderTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                timeFormatter.locale = Locale(identifier: "es-ES")
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.locale = Locale(identifier: "es-ES")
                print("⏰ RECORDATORIO DETECTADO: \(timeFormatter.string(from: reminderTime)) del \(dateFormatter.string(from: reminderTime))")
            } else {
                print("⏰ RECORDATORIO DETECTADO: Sin hora específica configurada")
            }
        } else {
            print("⏰ No se detectó solicitud de recordatorio")
        }
        
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
            categoryId: detectedCategory?.id,
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
        
        // Remove prefixes (but keep reminder words)
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
        
        // Remove time and date references to clean up the title (but keep reminder words for processing)
        let timePatterns = [
            "mañana(?! )", "tarde(?! )", "noche(?! )", "hoy(?! )", "después",
            "a las \\d+", "\\d+ de la mañana", "\\d+ de la tarde", "\\d+ de la noche",
            "\\d+:\\d+", "en la mañana", "por la mañana", "en la tarde", "por la tarde",
            "en la noche", "por la noche"
        ]
        
        for pattern in timePatterns {
            cleanedText = cleanedText.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            ).trimmingCharacters(in: .whitespaces)
        }
        
        // Remove reminder words AFTER processing for reminders
        let reminderPatternsToRemove = [
            "recordarme", "recuérdame", "recuerda", "quiero que recuerdes",
            "avisame", "avísame", "avisar", "avisa",
            "recordatorio", "alarma", "notificación"
        ]
        
        for reminderPattern in reminderPatternsToRemove {
            cleanedText = cleanedText.replacingOccurrences(
                of: reminderPattern,
                 with: "",
                options: .caseInsensitive
            ).trimmingCharacters(in: .whitespaces)
        }
        
        return cleanedText.capitalized
    }
    
    private func extractDateInfo(from text: String) -> (Date?, TaskItem.TaskType) {
        let today = Date()
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Primero, verificar fechas exactas (ej: "10 de agosto", "15 de diciembre")
        let monthNames = [
            "enero": 1, "febrero": 2, "marzo": 3, "abril": 4,
            "mayo": 5, "junio": 6, "julio": 7, "agosto": 8,
            "septiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12
        ]
        
        // Patrón para fechas exactas: "día de mes" o "día del mes"
        let exactDatePattern = "(\\d{1,2})\\s+de[l]?\\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)"
        
        if let regex = try? NSRegularExpression(pattern: exactDatePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText)) {
            
            if let dayRange = Range(match.range(at: 1), in: cleanText),
               let monthRange = Range(match.range(at: 2), in: cleanText),
               let day = Int(String(cleanText[dayRange])),
               let monthNumber = monthNames[String(cleanText[monthRange]).lowercased()] {
                
                let currentYear = calendar.component(.year, from: today)
                let currentMonth = calendar.component(.month, from: today)
                let currentDay = calendar.component(.day, from: today)
                
                // Determinar el año correcto
                var targetYear = currentYear
                
                // Si el mes ya pasó este año, usar el próximo año
                if monthNumber < currentMonth || (monthNumber == currentMonth && day < currentDay) {
                    targetYear += 1
                }
                
                if let exactDate = calendar.date(from: DateComponents(year: targetYear, month: monthNumber, day: day)) {
                    print("📅 Fecha exacta detectada: \(day) de \(String(cleanText[monthRange])) del \(targetYear)")
                    return (exactDate, .specific)
                }
            }
        }
        
        // Verificar "hoy" con prioridad más alta y más variaciones
        if cleanText.contains("hoy") || cleanText.contains("el día de hoy") || cleanText.contains("este día") {
            return (today, .specific)
        }
        
        // Verificar "esta mañana", "esta tarde", "esta noche" (también se refieren a hoy)
        if cleanText.contains("esta mañana") || cleanText.contains("esta tarde") || cleanText.contains("esta noche") {
            return (today, .specific)
        }
        
        // Verificar "mañana" (día siguiente)
        if cleanText.contains("mañana") && !cleanText.contains("esta mañana") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
            return (tomorrow, .specific)
        }
        
        // Verificar "pasado mañana"
        if cleanText.contains("pasado mañana") {
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)
            return (dayAfterTomorrow, .specific)
        }
        
        // Verificar días específicos de la semana
        let dayPatterns = [
            ("lunes", 2), ("martes", 3), ("miércoles", 4), ("jueves", 5),
            ("viernes", 6), ("sábado", 7), ("domingo", 1)
        ]
        
        for (dayName, weekday) in dayPatterns {
            if cleanText.contains(dayName) {
                let currentWeekday = calendar.component(.weekday, from: today)
                
                // Si es el mismo día de la semana y dice "hoy", usar hoy
                if weekday == currentWeekday && cleanText.contains("hoy") {
                    return (today, .specific)
                }
                
                // Si es el mismo día de la semana pero no dice "hoy", asumir la próxima semana
                if weekday == currentWeekday && !cleanText.contains("hoy") {
                    if let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: today) {
                        if let nextDate = calendar.nextDate(
                            after: nextWeekDate,
                            matching: DateComponents(weekday: weekday),
                            matchingPolicy: .previousTimePreservingSmallerComponents
                        ) {
                            return (nextDate, .specific)
                        }
                    }
                } else {
                    // Buscar el próximo día con ese nombre
                    if let nextDate = calendar.nextDate(
                        after: today,
                        matching: DateComponents(weekday: weekday),
                        matchingPolicy: .nextTime
                    ) {
                        return (nextDate, .specific)
                    }
                }
            }
        }
        
        // Verificar referencias temporales relativas
        if cleanText.contains("la próxima semana") || cleanText.contains("la siguiente semana") {
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)
            return (nextWeek, .specific)
        }
        
        if cleanText.contains("el próximo mes") || cleanText.contains("el siguiente mes") {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)
            return (nextMonth, .specific)
        }
        
        // Default to daily task if no specific date mentioned
        return (nil, .daily)
    }
    
    private func extractTimeInfo(from text: String, specificDate: Date?) -> (Bool, Date?) {
        // Palabras clave que indican intención de recordatorio
        let reminderKeywords = [
            "recordar", "recuérdame", "recuerda", "quiero que recuerdes",
            "avisame", "avísame", "avisar", "avisa", "avisarme",
            "recordatorio", "alarma", "notificación", "notificar",
            "que me recuerdes", "me recuerdes", "que me avises",
            "ponme un recordatorio", "pon un recordatorio",
            "no olvides", "no me olvides", "no se me olvide"
        ]
        
        // Patrones de tiempo más amplios y flexibles
        let timePatterns = [
            // Formato "a las X"
            ("a las (\\d+)", "hour_24"),
            ("a las (\\d+):(\\d+)", "hour_minute_24"),
            
            // Formato "X de la mañana/tarde/noche"
            ("(\\d+) de la mañana", "morning"),
            ("(\\d+) de la tarde", "afternoon"),
            ("(\\d+) de la noche", "night"),
            ("(\\d+):(\\d+) de la mañana", "morning_minute"),
            ("(\\d+):(\\d+) de la tarde", "afternoon_minute"),
            ("(\\d+):(\\d+) de la noche", "night_minute"),
            
            // Patrones con "por" y "en"
            ("por la mañana", "default_morning"),
            ("en la mañana", "default_morning"),
            ("por la tarde", "default_afternoon"),
            ("en la tarde", "default_afternoon"),
            ("por la noche", "default_night"),
            ("en la noche", "default_night"),
            
            // Patrones específicos de tiempo
            ("al mediodía", "noon"),
            ("a medianoche", "midnight"),
            ("al amanecer", "dawn"),
            ("al atardecer", "sunset"),
            
            // Patrones relativos
            ("dentro de (\\d+) hora", "relative_hour"),
            ("dentro de (\\d+) horas", "relative_hours"),
            ("en (\\d+) hora", "relative_hour"),
            ("en (\\d+) horas", "relative_hours"),
            
            // Patrones informales
            ("temprano", "early_morning"),
            ("muy temprano", "very_early"),
            ("tarde", "late_evening"),
            ("muy tarde", "very_late")
        ]
        
        let lowercaseText = text.lowercased()
        
        // Verificar si hay palabras clave de recordatorio
        let hasReminderKeyword = reminderKeywords.contains { keyword in
            lowercaseText.contains(keyword.lowercased())
        }
        
        // Buscar patrones de tiempo específicos
        for (pattern, timeType) in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let targetDate = specificDate ?? Date()
                let reminderTime = processTimePattern(match: match, timeType: timeType, text: text, targetDate: targetDate)
                
                if let reminderTime = reminderTime {
                    print("⏰ Recordatorio detectado con hora específica: \(formatTime(reminderTime))")
                    return (true, reminderTime)
                }
            }
        }
        
        // Si hay palabra clave de recordatorio pero no hora específica
        if hasReminderKeyword {
            let targetDate = specificDate ?? Date()
            
            // Verificar si es para hoy y ya es tarde, programar para mañana
            let currentHour = calendar.component(.hour, from: Date())
            let shouldScheduleForTomorrow = (specificDate == nil || calendar.isDate(targetDate, inSameDayAs: Date())) && currentHour >= 18
            
            let reminderDate = shouldScheduleForTomorrow ?
                calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate : targetDate
            
            let defaultReminderTime = calendar.date(
                bySettingHour: 10,
                minute: 0,
                second: 0,
                of: reminderDate
            )
            
            if shouldScheduleForTomorrow {
                print("⏰ Recordatorio detectado sin hora específica. Es tarde, programando para mañana a las 10:00 AM")
            } else {
                print("⏰ Recordatorio detectado sin hora específica. Configurando para las 10:00 AM")
            }
            
            return (true, defaultReminderTime)
        }
        
        // Detectar patrones implícitos de recordatorio (sin palabras clave explícitas)
        let implicitReminderPatterns = [
            "no me olvides", "que no se me olvide", "importante",
            "urgente", "crítico", "vital", "esencial"
        ]
        
        let hasImplicitReminder = implicitReminderPatterns.contains { pattern in
            lowercaseText.contains(pattern)
        }
        
        if hasImplicitReminder {
            let targetDate = specificDate ?? Date()
            let defaultReminderTime = calendar.date(
                bySettingHour: 10,
                minute: 0,
                second: 0,
                of: targetDate
            )
            
            print("⏰ Recordatorio implícito detectado. Configurando para las 10:00 AM")
            return (true, defaultReminderTime)
        }
        
        return (false, nil)
    }
    
    private func processTimePattern(match: NSTextCheckingResult, timeType: String, text: String, targetDate: Date) -> Date? {
        switch timeType {
        case "hour_24":
            if let hourRange = Range(match.range(at: 1), in: text),
               let hour = Int(String(text[hourRange])) {
                return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate)
            }
            
        case "hour_minute_24":
            if let hourRange = Range(match.range(at: 1), in: text),
               let minuteRange = Range(match.range(at: 2), in: text),
               let hour = Int(String(text[hourRange])),
               let minute = Int(String(text[minuteRange])) {
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate)
            }
            
        case "morning", "afternoon", "night":
            if let hourRange = Range(match.range(at: 1), in: text),
               let hour = Int(String(text[hourRange])) {
                let adjustedHour = adjustHour(hour, for: timeType)
                return calendar.date(bySettingHour: adjustedHour, minute: 0, second: 0, of: targetDate)
            }
            
        case "morning_minute", "afternoon_minute", "night_minute":
            if let hourRange = Range(match.range(at: 1), in: text),
               let minuteRange = Range(match.range(at: 2), in: text),
               let hour = Int(String(text[hourRange])),
               let minute = Int(String(text[minuteRange])) {
                let timeTypeBase = timeType.replacingOccurrences(of: "_minute", with: "")
                let adjustedHour = adjustHour(hour, for: timeTypeBase)
                return calendar.date(bySettingHour: adjustedHour, minute: minute, second: 0, of: targetDate)
            }
            
        case "default_morning":
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate)
            
        case "default_afternoon":
            return calendar.date(bySettingHour: 15, minute: 0, second: 0, of: targetDate)
            
        case "default_night":
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: targetDate)
            
        case "noon":
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: targetDate)
            
        case "midnight":
            return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: targetDate)
            
        case "dawn":
            return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: targetDate)
            
        case "sunset":
            return calendar.date(bySettingHour: 18, minute: 30, second: 0, of: targetDate)
            
        case "relative_hour", "relative_hours":
            if let hourRange = Range(match.range(at: 1), in: text),
               let hours = Int(String(text[hourRange])) {
                return calendar.date(byAdding: .hour, value: hours, to: Date())
            }
            
        case "early_morning":
            return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: targetDate)
            
        case "very_early":
            return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: targetDate)
            
        case "late_evening":
            return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: targetDate)
            
        case "very_late":
            return calendar.date(bySettingHour: 23, minute: 0, second: 0, of: targetDate)
            
        default:
            return nil
        }
        
        return nil
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es-ES")
        return formatter.string(from: date)
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
    
    // MARK: - Category Detection
    
    private func extractCategoryInfo(from text: String) -> TaskCategory? {
        let lowercaseText = text.lowercased()
        
        // Definir palabras clave para cada categoría
        let categoryKeywords: [String: [String]] = [
            "Casa": [
                "limpiar", "limpieza", "aspirar", "barrer", "trapear", "fregar",
                "lavar", "lavandería", "ropa", "planchar", "cocinar", "cocina",
                "ordenar", "organizar", "casa", "hogar", "baño", "habitación",
                "jardín", "jardinería", "plantas", "regar", "basura", "residuos",
                "ventanas", "polvo", "cama", "tender", "doblar", "guardar"
            ],
            
            "Trabajo": [
                "reunión", "meeting", "junta", "presentación", "proyecto", "informe",
                "reporte", "email", "correo", "llamada", "cliente", "jefe", "oficina",
                "trabajo", "laboral", "empresa", "entrega", "deadline", "fecha límite",
                "propuesta", "cotización", "factura", "nomina", "pago", "cobrar",
                "contratos", "documentos", "archivo", "enviar", "revisar", "aprobar"
            ],
            
            "Personal": [
                "cumpleaños", "aniversario", "familia", "amigos", "pareja", "cita",
                "personal", "hobby", "pasatiempo", "relajarse", "descansar",
                "tiempo libre", "vacaciones", "viaje", "planificar", "llamar",
                "visitar", "celebrar", "regalo", "comprar regalo", "felicitar",
                "escribir", "leer", "música", "película", "serie", "entretenimiento"
            ],
            
            "Salud": [
                "médico", "doctor", "cita médica", "hospital", "clínica", "dentista",
                "chequeo", "examen", "análisis", "medicamentos", "medicina", "pastillas",
                "vitaminas", "terapia", "fisioterapia", "psicólogo", "nutricionista",
                "dieta", "salud", "bienestar", "síntomas", "dolor", "tratamiento",
                "vacuna", "inyección", "receta", "farmacia", "seguro médico"
            ],
            
            "Ejercicio": [
                "ejercicio", "gym", "gimnasio", "correr", "caminar", "trotar",
                "natación", "nadar", "piscina", "yoga", "pilates", "cardio",
                "pesas", "entrenamiento", "fitness", "deporte", "fútbol", "tenis",
                "bicicleta", "ciclismo", "escalada", "hiking", "caminata",
                "estirar", "abdominales", "flexiones", "sentadillas", "rutina"
            ],
            
            "Estudio": [
                "estudiar", "examen", "tarea", "universidad", "colegio", "escuela",
                "clase", "curso", "materia", "asignatura", "libro", "leer",
                "investigar", "ensayo", "trabajo", "proyecto escolar", "presentación",
                "biblioteca", "laboratorio", "práctica", "ejercicios", "deberes",
                "aprender", "repasar", "memorizar", "notas", "apuntes", "carrera"
            ],
            
            "Compras": [
                "comprar", "compras", "mercado", "supermercado", "tienda", "centro comercial",
                "mall", "farmacia", "ferretería", "verduras", "frutas", "carne",
                "pan", "leche", "huevos", "despensa", "alimentos", "comida",
                "ropa", "zapatos", "regalo", "electrodomésticos", "muebles",
                "online", "internet", "delivery", "pedido", "orden", "lista"
            ]
        ]
        
        // Buscar coincidencias y calcular puntuación
        var categoryScores: [String: Int] = [:]
        
        for (categoryName, keywords) in categoryKeywords {
            var score = 0
            for keyword in keywords {
                if lowercaseText.contains(keyword) {
                    // Dar más peso a palabras más específicas (más largas)
                    score += keyword.count > 6 ? 3 : (keyword.count > 4 ? 2 : 1)
                }
            }
            if score > 0 {
                categoryScores[categoryName] = score
            }
        }
        
        // Encontrar la categoría con mayor puntuación
        if let bestCategory = categoryScores.max(by: { $0.value < $1.value }) {
            // Solo asignar categoría si hay una puntuación mínima
            if bestCategory.value >= 2 {
                let matchedCategory = TaskCategory.defaultCategories.first { $0.name == bestCategory.key }
                
                if let category = matchedCategory {
                    print("🏷️ CATEGORÍA DETECTADA: \(category.name) (puntuación: \(bestCategory.value))")
                    return category
                }
            }
        }
        
        print("🏷️ No se detectó categoría específica - usando categoría General")
        return TaskCategory.defaultCategories.first { $0.name == "General" }
    }
}
