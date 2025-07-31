import Foundation

/// Protocolo para validación de datos
protocol Validatable {
    func validate() throws
}

/// Errores de validación específicos
enum ValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong(maxLength: Int)
    case invalidCharacters
    case futureTimeRequired
    case invalidCategory
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "El título no puede estar vacío"
        case .titleTooLong(let maxLength):
            return "El título no puede exceder \(maxLength) caracteres"
        case .invalidCharacters:
            return "El título contiene caracteres no válidos"
        case .futureTimeRequired:
            return "La hora del recordatorio debe ser futura"
        case .invalidCategory:
            return "La categoría seleccionada no es válida"
        }
    }
}

/// Validador para datos de tareas
struct TaskValidator {
    static let maxTitleLength = 100
    static let minTitleLength = 1
    
    /// Valida el título de una tarea
    static func validateTitle(_ title: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard trimmedTitle.count >= minTitleLength else {
            throw ValidationError.emptyTitle
        }
        
        guard trimmedTitle.count <= maxTitleLength else {
            throw ValidationError.titleTooLong(maxLength: maxTitleLength)
        }
        
        // Verificar caracteres válidos (letras, números, espacios y algunos símbolos)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(.punctuationCharacters)
            .union(.symbols)
        
        guard trimmedTitle.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            throw ValidationError.invalidCharacters
        }
    }
    
    /// Valida la hora del recordatorio
    static func validateReminderTime(_ time: Date?) throws {
        guard let time = time else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Para recordatorios diarios, verificar que la hora no sea en el pasado del día actual
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = calendar.component(.hour, from: time)
        components.minute = calendar.component(.minute, from: time)
        components.second = 0
        
        guard let todayWithReminderTime = calendar.date(from: components),
              todayWithReminderTime > now else {
            throw ValidationError.futureTimeRequired
        }
    }
    
    /// Valida la categoría
    static func validateCategory(_ categoryId: UUID?, against availableCategories: [TaskCategory]) throws {
        guard let categoryId = categoryId else { return } // Categoría opcional
        
        guard availableCategories.contains(where: { $0.id == categoryId }) else {
            throw ValidationError.invalidCategory
        }
    }
}

/// Extensión para TaskItem que implementa validación
extension TaskItem: Validatable {
    func validate() throws {
        try TaskValidator.validateTitle(self.title)
        try TaskValidator.validateReminderTime(self.reminderTime)
    }
}

/// Validador para entrada de usuario
struct UserInputValidator {
    static let maxNameLength = 50
    
    /// Valida el nombre del usuario
    static func validateUserName(_ name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Si está vacío, permitir (nombre opcional)
        guard !trimmedName.isEmpty else { return "" }
        
        // Limitar longitud
        let limitedName = String(trimmedName.prefix(maxNameLength))
        
        // Filtrar solo caracteres alfanuméricos y espacios
        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        let filteredName = limitedName.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        
        return filteredName
    }
    
    /// Sanitiza texto general para prevenir problemas
    static func sanitizeText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ") // Eliminar espacios dobles
    }
}
