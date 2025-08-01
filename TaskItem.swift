import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var categoryId: UUID?
    var hasReminder: Bool
    var reminderTime: Date?
    var repeatDaily: Bool
    var specificDate: Date? // Nueva propiedad para tareas específicas de fecha
    var taskType: TaskType // Nueva propiedad para distinguir tipo de tarea
    
    enum TaskType: String, Codable, CaseIterable {
        case daily = "daily"
        case specific = "specific"
        
        var displayName: String {
            switch self {
            case .daily:
                return "Diaria"
            case .specific:
                return "Específica"
            }
        }
    }

    init(title: String, categoryId: UUID? = nil, hasReminder: Bool = false, reminderTime: Date? = nil, repeatDaily: Bool = true, specificDate: Date? = nil, taskType: TaskType = .daily) {
        self.id = UUID()
        self.title = title
        self.categoryId = categoryId
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
        self.repeatDaily = repeatDaily
        self.specificDate = specificDate
        self.taskType = taskType
    }
    
    // Computed property para determinar si la tarea es para una fecha específica
    var isSpecificDateTask: Bool {
        return taskType == .specific && specificDate != nil
    }
    
    // Computed property para obtener la fecha de la tarea (hoy si es diaria, o la fecha específica)
    var effectiveDate: Date {
        if isSpecificDateTask, let date = specificDate {
            return Calendar.current.startOfDay(for: date)
        }
        return Calendar.current.startOfDay(for: Date())
    }
}
