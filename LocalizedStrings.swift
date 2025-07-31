import Foundation

/// Sistema de localización centralizado para la aplicación
struct LocalizedStrings {
    
    // MARK: - General
    static let appName = NSLocalizedString("app.name", value: "Lista Pendientes", comment: "Application name")
    static let cancel = NSLocalizedString("general.cancel", value: "Cancelar", comment: "Cancel button")
    static let save = NSLocalizedString("general.save", value: "Guardar", comment: "Save button")
    static let delete = NSLocalizedString("general.delete", value: "Eliminar", comment: "Delete button")
    static let edit = NSLocalizedString("general.edit", value: "Editar", comment: "Edit button")
    static let done = NSLocalizedString("general.done", value: "Listo", comment: "Done button")
    static let continueButton = NSLocalizedString("general.continue", value: "Continuar", comment: "Continue button")
    
    // MARK: - Welcome Screen
    static let welcomeTitle = NSLocalizedString("welcome.title", value: "¡Bienvenido a", comment: "Welcome screen title")
    static let welcomeAppName = NSLocalizedString("welcome.app_name", value: "Lista Pendientes!", comment: "App name in welcome")
    static let welcomeDescription = NSLocalizedString("welcome.description", value: "Para hacer tu experiencia más personal, nos gustaría conocerte mejor", comment: "Welcome description")
    static let welcomeNamePrompt = NSLocalizedString("welcome.name_prompt", value: "¿Cómo te llamas?", comment: "Name input prompt")
    static let welcomeNamePlaceholder = NSLocalizedString("welcome.name_placeholder", value: "Tu nombre aquí...", comment: "Name input placeholder")
    static let welcomeNameHint = NSLocalizedString("welcome.name_hint", value: "Puedes usar tu nombre real o un apodo", comment: "Name input hint")
    static let welcomeSkip = NSLocalizedString("welcome.skip", value: "Continuar sin nombre", comment: "Skip name entry")
    
    // MARK: - Tab Bar
    static let tabToday = NSLocalizedString("tab.today", value: "Hoy", comment: "Today tab")
    static let tabTasks = NSLocalizedString("tab.tasks", value: "Tareas", comment: "Tasks tab")
    static let tabStats = NSLocalizedString("tab.stats", value: "Estadísticas", comment: "Statistics tab")
    static let tabHistory = NSLocalizedString("tab.history", value: "Historial", comment: "History tab")
    
    // MARK: - Tasks
    static let tasksTitle = NSLocalizedString("tasks.title", value: "Mis Tareas", comment: "Tasks screen title")
    static let taskAdd = NSLocalizedString("tasks.add", value: "Agregar Tarea", comment: "Add task button")
    static let taskTitlePlaceholder = NSLocalizedString("tasks.title_placeholder", value: "Título de la tarea", comment: "Task title placeholder")
    static let taskCategoryPlaceholder = NSLocalizedString("tasks.category_placeholder", value: "Seleccionar categoría", comment: "Task category placeholder")
    static let taskReminderToggle = NSLocalizedString("tasks.reminder_toggle", value: "Recordatorio", comment: "Reminder toggle")
    static let taskReminderTime = NSLocalizedString("tasks.reminder_time", value: "Hora del recordatorio", comment: "Reminder time")
    static let taskRepeatDaily = NSLocalizedString("tasks.repeat_daily", value: "Repetir diariamente", comment: "Repeat daily option")
    
    // MARK: - Today View
    static let todayGreeting = NSLocalizedString("today.greeting", value: "¡Hola", comment: "Today greeting")
    static let todayProgress = NSLocalizedString("today.progress", value: "Progreso de hoy", comment: "Today's progress")
    static let todayCompleted = NSLocalizedString("today.completed", value: "completadas", comment: "tasks completed")
    static let todayNoTasks = NSLocalizedString("today.no_tasks", value: "¡Excelente! No tienes tareas pendientes por hoy", comment: "No tasks message")
    static let todayAllDone = NSLocalizedString("today.all_done", value: "¡Felicitaciones! Completaste todas las tareas de hoy", comment: "All tasks done message")
    
    // MARK: - Categories
    static let categoryWork = NSLocalizedString("category.work", value: "Trabajo", comment: "Work category")
    static let categoryPersonal = NSLocalizedString("category.personal", value: "Personal", comment: "Personal category")
    static let categoryHealth = NSLocalizedString("category.health", value: "Salud", comment: "Health category")
    static let categoryHome = NSLocalizedString("category.home", value: "Hogar", comment: "Home category")
    static let categoryStudy = NSLocalizedString("category.study", value: "Estudio", comment: "Study category")
    static let categoryShopping = NSLocalizedString("category.shopping", value: "Compras", comment: "Shopping category")
    
    // MARK: - Statistics
    static let statsTitle = NSLocalizedString("stats.title", value: "Estadísticas", comment: "Statistics title")
    static let statsPoints = NSLocalizedString("stats.points", value: "Puntos", comment: "Points label")
    static let statsStreak = NSLocalizedString("stats.streak", value: "Racha", comment: "Streak label")
    static let statsWeeklyProgress = NSLocalizedString("stats.weekly_progress", value: "Progreso Semanal", comment: "Weekly progress")
    static let statsMonthlyProgress = NSLocalizedString("stats.monthly_progress", value: "Progreso Mensual", comment: "Monthly progress")
    
    // MARK: - Notifications
    static let notificationTitle = NSLocalizedString("notification.title", value: "Recordatorio de tarea", comment: "Notification title")
    static let notificationBodyWithName = NSLocalizedString("notification.body_with_name", value: "Hola %@, no olvides: %@", comment: "Notification body with name")
    static let notificationBodyWithoutName = NSLocalizedString("notification.body_without_name", value: "No olvides: %@", comment: "Notification body without name")
    static let notificationCelebration = NSLocalizedString("notification.celebration", value: "¡Felicitaciones! Completaste %d tareas hoy", comment: "Celebration notification")
    
    // MARK: - Errors
    static let errorGeneric = NSLocalizedString("error.generic", value: "Ha ocurrido un error inesperado", comment: "Generic error message")
    static let errorDataCorruption = NSLocalizedString("error.data_corruption", value: "Los datos están corruptos y no se pueden recuperar", comment: "Data corruption error")
    static let errorFileNotFound = NSLocalizedString("error.file_not_found", value: "No se pudo encontrar el archivo", comment: "File not found error")
    static let errorEncodingFailed = NSLocalizedString("error.encoding_failed", value: "Error al guardar los datos", comment: "Encoding failed error")
    static let errorDecodingFailed = NSLocalizedString("error.decoding_failed", value: "Error al cargar los datos", comment: "Decoding failed error")
    static let errorInvalidTaskData = NSLocalizedString("error.invalid_task_data", value: "Los datos de la tarea son inválidos", comment: "Invalid task data error")
    static let errorCategoryNotFound = NSLocalizedString("error.category_not_found", value: "La categoría no existe", comment: "Category not found error")
    static let errorNotificationPermissionDenied = NSLocalizedString("error.notification_permission_denied", value: "Permisos de notificación denegados", comment: "Notification permission denied error")
    
    // MARK: - History
    static let historyTitle = NSLocalizedString("history.title", value: "Historial", comment: "History title")
    static let historyNoRecords = NSLocalizedString("history.no_records", value: "No hay registros disponibles", comment: "No history records")
    static let historyTasksCompleted = NSLocalizedString("history.tasks_completed", value: "%d de %d tareas completadas", comment: "Tasks completed format")
    
    // MARK: - Accessibility
    static let accessibilityTaskCompleted = NSLocalizedString("accessibility.task_completed", value: "Tarea completada", comment: "Task completed accessibility")
    static let accessibilityTaskPending = NSLocalizedString("accessibility.task_pending", value: "Tarea pendiente", comment: "Task pending accessibility")
    static let accessibilityAddTask = NSLocalizedString("accessibility.add_task", value: "Agregar nueva tarea", comment: "Add task accessibility")
    static let accessibilityDeleteTask = NSLocalizedString("accessibility.delete_task", value: "Eliminar tarea", comment: "Delete task accessibility")
}

// MARK: - Formatters
extension LocalizedStrings {
    
    /// Formatea el saludo personalizado
    static func greeting(name: String) -> String {
        if name.isEmpty {
            return NSLocalizedString("today.greeting_generic", value: "¡Hola!", comment: "Generic greeting")
        } else {
            return String(format: NSLocalizedString("today.greeting_with_name", value: "¡Hola %@!", comment: "Greeting with name"), name)
        }
    }
    
    /// Formatea el progreso de tareas
    static func taskProgress(completed: Int, total: Int) -> String {
        return String(format: NSLocalizedString("progress.format", value: "%d de %d %@", comment: "Progress format"), completed, total, LocalizedStrings.todayCompleted)
    }
    
    /// Formatea la notificación con nombre personalizado
    static func notificationBody(name: String, taskTitle: String) -> String {
        if name.isEmpty {
            return String(format: notificationBodyWithoutName, taskTitle)
        } else {
            return String(format: notificationBodyWithName, name, taskTitle)
        }
    }
    
    /// Formatea la celebración de tareas completadas
    static func celebrationMessage(taskCount: Int) -> String {
        return String(format: notificationCelebration, taskCount)
    }
}
