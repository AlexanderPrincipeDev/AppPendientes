import UIKit
import SwiftUI

/// Manager para manejar feedback háptico en toda la aplicación
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    /// Feedback háptico ligero para interacciones menores
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Feedback háptico medio para interacciones normales
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Feedback háptico fuerte para interacciones importantes
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    /// Feedback para acciones exitosas
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Feedback para advertencias
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Feedback para errores
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Contextualized Feedback
    /// Feedback cuando se completa una tarea
    func taskCompleted() {
        success()
    }
    
    /// Feedback cuando se descompleta una tarea
    func taskUncompleted() {
        lightImpact()
    }
    
    /// Feedback cuando se crea una nueva tarea
    func taskCreated() {
        mediumImpact()
    }
    
    /// Feedback cuando se elimina una tarea
    func taskDeleted() {
        warning()
    }
    
    /// Feedback para navegación (cambios de pestañas, vistas)
    func navigation() {
        lightImpact()
    }
    
    /// Feedback para selección de elementos
    func selection() {
        lightImpact()
    }
    
    /// Feedback para acciones de botones importantes
    func buttonPress() {
        mediumImpact()
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