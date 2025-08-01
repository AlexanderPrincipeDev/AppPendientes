import UIKit
import SwiftUI

/// Manager para manejar feedback háptico en toda la aplicación
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    // Configuración de hápticos
    @Published var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "hapticsEnabled")
        }
    }
    
    @Published var hapticsIntensity: Float {
        didSet {
            UserDefaults.standard.set(hapticsIntensity, forKey: "hapticsIntensity")
        }
    }
    
    private init() {
        self.isHapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.hapticsIntensity = UserDefaults.standard.object(forKey: "hapticsIntensity") as? Float ?? 1.0
    }
    
    // MARK: - Impact Feedback
    /// Feedback háptico ligero para interacciones menores
    func lightImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred(intensity: CGFloat(hapticsIntensity))
    }
    
    /// Feedback háptico medio para interacciones normales
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred(intensity: CGFloat(hapticsIntensity))
    }
    
    /// Feedback háptico fuerte para interacciones importantes
    func heavyImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        impactFeedback.impactOccurred(intensity: CGFloat(hapticsIntensity))
    }
    
    // MARK: - Notification Feedback
    /// Feedback para acciones exitosas
    func success() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Feedback para advertencias
    func warning() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Feedback para errores
    func error() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Contextualized Feedback para Lista de Tareas
    
    /// Feedback cuando se completa una tarea
    func taskCompleted() {
        guard isHapticsEnabled else { return }
        // Patrón de éxito + impacto medio
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
    }
    
    /// Feedback cuando se desmarca una tarea
    func taskUncompleted() {
        guard isHapticsEnabled else { return }
        lightImpact()
    }
    
    /// Feedback cuando se crea una nueva tarea
    func taskCreated() {
        guard isHapticsEnabled else { return }
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.lightImpact()
        }
    }
    
    /// Feedback cuando se elimina una tarea
    func taskDeleted() {
        guard isHapticsEnabled else { return }
        warning()
    }
    
    /// Feedback cuando se edita una tarea
    func taskEdited() {
        guard isHapticsEnabled else { return }
        lightImpact()
    }
    
    /// Feedback cuando se alcanza un logro/nivel
    func achievementUnlocked() {
        guard isHapticsEnabled else { return }
        // Patrón especial para logros
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.lightImpact()
        }
    }
    
    /// Feedback cuando se completan todas las tareas del día
    func allTasksCompleted() {
        guard isHapticsEnabled else { return }
        // Patrón de celebración
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.heavyImpact()
        }
    }
    
    /// Feedback para navegación entre tabs
    func tabSwitched() {
        guard isHapticsEnabled else { return }
        lightImpact()
    }
    
    /// Feedback para acciones de pull-to-refresh
    func refreshTriggered() {
        guard isHapticsEnabled else { return }
        mediumImpact()
    }
    
    /// Feedback para mostrar/ocultar elementos
    func elementToggled() {
        guard isHapticsEnabled else { return }
        lightImpact()
    }
    
    /// Feedback para el inicio de grabación de voz
    func voiceRecordingStarted() {
        guard isHapticsEnabled else { return }
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Feedback para el final de grabación de voz
    func voiceRecordingStopped() {
        guard isHapticsEnabled else { return }
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Feedback cuando se reconoce correctamente la voz
    func voiceRecognitionSuccess() {
        guard isHapticsEnabled else { return }
        success()
    }
    
    /// Feedback cuando falla el reconocimiento de voz
    func voiceRecognitionFailed() {
        guard isHapticsEnabled else { return }
        error()
    }
    
    // MARK: - Patterns Complejos
    
    /// Patrón de "heartbeat" para recordatorios importantes
    func heartbeatPattern() {
        guard isHapticsEnabled else { return }
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.lightImpact()
        }
    }
    
    /// Patrón de "construcción" para crear múltiples tareas
    func buildingPattern(step: Int, totalSteps: Int) {
        guard isHapticsEnabled else { return }
        let intensity = Float(step) / Float(totalSteps)
        
        if intensity <= 0.33 {
            lightImpact()
        } else if intensity <= 0.66 {
            mediumImpact()
        } else {
            heavyImpact()
        }
    }
    
    /// Patrón de "progreso" para barras de progreso
    func progressPattern(progress: Float) {
        guard isHapticsEnabled else { return }
        
        switch progress {
        case 0.25:
            lightImpact()
        case 0.5:
            mediumImpact()
        case 0.75:
            heavyImpact()
        case 1.0:
            allTasksCompleted()
        default:
            break
        }
    }
    
    // MARK: - Selection Feedback (iOS 13+)
    
    /// Feedback para selección en listas
    func selectionChanged() {
        guard isHapticsEnabled else { return }
        if #available(iOS 13.0, *) {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.prepare()
            selectionFeedback.selectionChanged()
        } else {
            lightImpact()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Preparar generadores para mejor rendimiento
    func prepareGenerators() {
        guard isHapticsEnabled else { return }
        
        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        let notificationGenerator = UINotificationFeedbackGenerator()
        
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// Verificar si el dispositivo soporta hápticos
    func deviceSupportsHaptics() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Configurar intensidad personalizada
    func setIntensity(_ intensity: Float) {
        hapticsIntensity = max(0.0, min(1.0, intensity))
    }
    
    /// Habilitar/deshabilitar hápticos
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Modifier para agregar feedback háptico a cualquier vista
    func hapticFeedback(_ feedback: @escaping () -> Void) -> some View {
        self.onTapGesture {
            feedback()
        }
    }
    
    /// Modifier conveniente para feedback ligero
    func lightHaptic() -> some View {
        self.hapticFeedback {
            HapticManager.shared.lightImpact()
        }
    }
    
    /// Modifier conveniente para feedback medio
    func mediumHaptic() -> some View {
        self.hapticFeedback {
            HapticManager.shared.mediumImpact()
        }
    }
    
    /// Modifier conveniente para feedback de éxito
    func successHaptic() -> some View {
        self.hapticFeedback {
            HapticManager.shared.success()
        }
    }
}
