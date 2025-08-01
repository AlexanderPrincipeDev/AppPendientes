import Foundation
import SwiftUI

@MainActor
class ChoreModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var records: [DailyRecord] = []
    @Published var gamification = GamificationData()
    @Published var categories: [TaskCategory] = []
    @Published var userName: String = ""
    @Published var isFirstLaunch: Bool = true
    
    // MARK: - Habit System
    @Published var habits: [Habit] = []
    @Published var habitEntries: [HabitEntry] = []
    @Published var habitStreaks: [HabitStreak] = []
    
    private let notificationService = NotificationService.shared

    private let tasksFile = "tasks.json"
    private let recordsFile = "records.json"
    private let gamificationFile = "gamification.json"
    private let categoriesFile = "categories.json"
    private let userDataFile = "userData.json"
    // MARK: - Habit Files
    private let habitsFile = "habits.json"
    private let habitEntriesFile = "habitEntries.json"
    private let habitStreaksFile = "habitStreaks.json"

    init() {
        loadAll()
    }

    private var tasksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(tasksFile)
    }
    private var recordsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(recordsFile)
    }
    private var gamificationURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(gamificationFile)
    }
    private var categoriesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(categoriesFile)
    }
    private var userDataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(userDataFile)
    }
    // MARK: - Habit URLs
    private var habitsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(habitsFile)
    }
    private var habitEntriesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(habitEntriesFile)
    }
    private var habitStreaksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(habitStreaksFile)
    }

    func loadAll() {
        // Load categories first
        if let data = try? Data(contentsOf: categoriesURL),
           let decoded = try? JSONDecoder().decode([TaskCategory].self, from: data) {
            categories = decoded
        } else {
            categories = TaskCategory.defaultCategories
            saveCategories()
        }
        
        if let data = try? Data(contentsOf: tasksURL),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        } else {
            // Iniciar con lista vacía
            tasks = []
            saveTasks()
        }
        if let data = try? Data(contentsOf: recordsURL),
           let decoded = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            records = decoded
        }
        if let data = try? Data(contentsOf: gamificationURL),
           let decoded = try? JSONDecoder().decode(GamificationData.self, from: data) {
            gamification = decoded
        }
        if let data = try? Data(contentsOf: userDataURL),
           let decoded = try? JSONDecoder().decode(UserData.self, from: data) {
            userName = decoded.name
            isFirstLaunch = decoded.isFirstLaunch
        }
        // MARK: - Load Habits
        if let data = try? Data(contentsOf: habitsURL),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            habits = []
            saveHabits()
        }
        if let data = try? Data(contentsOf: habitEntriesURL),
           let decoded = try? JSONDecoder().decode([HabitEntry].self, from: data) {
            habitEntries = decoded
        } else {
            habitEntries = []
            saveHabitEntries()
        }
        if let data = try? Data(contentsOf: habitStreaksURL),
           let decoded = try? JSONDecoder().decode([HabitStreak].self, from: data) {
            habitStreaks = decoded
        } else {
            habitStreaks = []
            saveHabitStreaks()
        }
        
        // Limpiar tareas huérfanas después de cargar los datos
        cleanupOrphanedTasks()
        
        // Asegurar que el registro de hoy tenga todas las tareas actuales
        syncTodayRecord()
        
        // Actualizar widget con los datos cargados
        updateWidgetData()
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            try? data.write(to: tasksURL)
        }
        // Sincronizar tareas específicas de hoy con el registro diario
        syncTodaySpecificTasks()
    }
    func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: recordsURL)
        }
    }
    func saveGamification() {
        if let data = try? JSONEncoder().encode(gamification) {
            try? data.write(to: gamificationURL)
        }
    }
    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            try? data.write(to: categoriesURL)
        }
    }
    func saveUserData() {
        let userData = UserData(name: userName, isFirstLaunch: isFirstLaunch)
        if let data = try? JSONEncoder().encode(userData) {
            try? data.write(to: userDataURL)
        }
    }
    // MARK: - Habit Saving
    func saveHabits() {
        if let data = try? JSONEncoder().encode(habits) {
            try? data.write(to: habitsURL)
        }
    }
    func saveHabitEntries() {
        if let data = try? JSONEncoder().encode(habitEntries) {
            try? data.write(to: habitEntriesURL)
        }
    }
    func saveHabitStreaks() {
        if let data = try? JSONEncoder().encode(habitStreaks) {
            try? data.write(to: habitStreaksURL)
        }
    }

    private func todayKey() -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    var todayRecord: DailyRecord {
        let key = todayKey()
        if let idx = records.firstIndex(where: { $0.date == key }) {
            return records[idx]
        }
        let statuses = tasks.map { TaskStatus(taskId: $0.id, completed: false) }
        let rec = DailyRecord(date: key, statuses: statuses)
        records.insert(rec, at: 0)
        saveRecords()
        return rec
    }
    
    private func syncTodayRecord() {
        let key = todayKey()
        
        // Buscar o crear el registro de hoy
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            // El registro ya existe, asegurar que tenga todas las tareas actuales
            let currentStatusIds = Set(records[rIndex].statuses.map { $0.taskId })
            
            // Agregar tareas faltantes al registro de hoy
            for task in tasks {
                if !currentStatusIds.contains(task.id) {
                    let newStatus = TaskStatus(taskId: task.id, completed: false, completedAt: nil)
                    records[rIndex].statuses.append(newStatus)
                }
            }
            
            // Guardar si se agregaron nuevas tareas
            if records[rIndex].statuses.count != currentStatusIds.count {
                saveRecords()
            }
        } else {
            // No existe registro para hoy, crearlo con todas las tareas
            let statuses = tasks.map { TaskStatus(taskId: $0.id, completed: false) }
            let newRecord = DailyRecord(date: key, statuses: statuses)
            records.insert(newRecord, at: 0)
            saveRecords()
        }
    }
    
    private func syncTodaySpecificTasks() {
        let key = todayKey()
        let today = Date()
        
        // Buscar tareas específicas creadas para hoy
        let todaySpecificTasks = tasks.filter { task in
            if task.taskType == .specific, let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: today)
            }
            return false
        }
        
        // Asegurar que existe un registro para hoy
        var recordIndex = records.firstIndex(where: { $0.date == key })
        if recordIndex == nil {
            let newRecord = DailyRecord(date: key, statuses: [])
            records.insert(newRecord, at: 0)
            recordIndex = 0
        }
        
        guard let rIndex = recordIndex else { return }
        
        var hasChanges = false
        
        // Agregar las tareas específicas de hoy al registro si no están ya
        for task in todaySpecificTasks {
            if !records[rIndex].statuses.contains(where: { $0.taskId == task.id }) {
                let newStatus = TaskStatus(taskId: task.id, completed: false, completedAt: nil)
                records[rIndex].statuses.append(newStatus)
                hasChanges = true
            }
        }
        
        // Guardar si hubo cambios
        if hasChanges {
            saveRecords()
            updateWidgetData()
            objectWillChange.send()
        }
    }
    
    func cleanupOrphanedTasks() {
        let key = todayKey()
        guard let idx = records.firstIndex(where: { $0.date == key }) else { return }
        
        let existingTaskIds = Set(tasks.map { $0.id })
        let originalCount = records[idx].statuses.count
        
        // Remover statuses de tareas que ya no existen
        records[idx].statuses.removeAll { status in
            !existingTaskIds.contains(status.taskId)
        }
        
        // Si se removieron tareas huérfanas, guardar los cambios
        if records[idx].statuses.count != originalCount {
            saveRecords()
        }
    }

    func toggle(taskId: UUID) {
        let key = todayKey()
        guard let rIndex = records.firstIndex(where: { $0.date == key }),
              let sIndex = records[rIndex].statuses.firstIndex(where: { $0.taskId == taskId }) else { return }
        
        let wasCompleted = records[rIndex].statuses[sIndex].completed
        records[rIndex].statuses[sIndex].completed.toggle()
        
        // Add completion time if task is being completed
        if !wasCompleted && records[rIndex].statuses[sIndex].completed {
            records[rIndex].statuses[sIndex].completedAt = Date()
            // Award points for completing task
            gamification.addPoints(5)
            
            // Check if all tasks are now completed
            checkForDayCompletion()
        }
        
        saveRecords()
        saveGamification()
        updateWidgetData() // Actualizar widget cuando cambie el estado
        objectWillChange.send()
    }
    
    private func checkForDayCompletion() {
        let today = todayRecord
        let totalTasks = today.statuses.count
        let completedTasks = today.statuses.filter { $0.completed }.count
        
        // Si se completaron todas las tareas y hay al menos una tarea
        if totalTasks > 0 && completedTasks == totalTasks {
            // Enviar notificación de felicitación
            notificationService.sendCompletionCelebration(completedTasks: completedTasks)
            
            // Otorgar puntos bonus por día perfecto
            gamification.addPoints(20)
            saveGamification()
        }
    }

    func addTask(title: String, categoryId: UUID? = nil, hasReminder: Bool = false, reminderTime: Date? = nil) {
        let item = TaskItem(title: title, categoryId: categoryId, hasReminder: hasReminder, reminderTime: reminderTime)
        tasks.append(item)
        saveTasks()
        
        // Schedule notification if reminder is set
        if hasReminder, let reminderTime = reminderTime {
            notificationService.scheduleTaskReminder(for: item, at: reminderTime, repeatDaily: item.repeatDaily)
        }
        
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            records[rIndex].statuses.append(TaskStatus(taskId: item.id, completed: false, completedAt: nil))
        }
        saveRecords()
        updateWidgetData() // Actualizar widget cuando se agregue una tarea
        objectWillChange.send()
    }
    
    func updateTaskReminder(taskId: UUID, hasReminder: Bool, reminderTime: Date? = nil, repeatDaily: Bool = true) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        // Cancel existing notification
        notificationService.cancelNotification(for: taskId)
        
        // Update task
        tasks[index].hasReminder = hasReminder
        tasks[index].reminderTime = reminderTime
        tasks[index].repeatDaily = repeatDaily
        
        // Schedule new notification if needed
        if hasReminder, let reminderTime = reminderTime {
            notificationService.scheduleTaskReminder(for: tasks[index], at: reminderTime, repeatDaily: repeatDaily)
        }
        
        saveTasks()
        objectWillChange.send()
    }
    
    func deleteTask(taskId: UUID) {
        // Cancel notification
        notificationService.cancelNotification(for: taskId)
        
        // Remove task
        tasks.removeAll { $0.id == taskId }
        
        // Remove from all records
        for i in 0..<records.count {
            records[i].statuses.removeAll { $0.taskId == taskId }
        }
        
        saveTasks()
        saveRecords()
        updateWidgetData() // Actualizar widget cuando se elimine una tarea
        objectWillChange.send()
    }
    
    // MARK: - Task Reordering Methods
    
    /// Mueve una tarea desde una posición a otra
    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        saveTasks()
        updateTaskOrder()
        HapticManager.shared.lightImpact()
    }
    
    /// Mueve tareas específicas dentro de una fecha
    func moveSpecificTasks(for date: Date, from source: IndexSet, to destination: Int) {
        var specificTasks = getTasksForDate(date)
        specificTasks.move(fromOffsets: source, toOffset: destination)
        
        // Actualizar el orden en el array principal
        updateSpecificTasksOrder(for: date, orderedTasks: specificTasks)
        saveTasks()
        HapticManager.shared.lightImpact()
    }
    
    /// Actualiza el orden de las tareas específicas para una fecha
    private func updateSpecificTasksOrder(for date: Date, orderedTasks: [TaskItem]) {
        // Remover las tareas específicas de esa fecha del array principal
        tasks.removeAll { task in
            if task.taskType == .specific, let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: date)
            }
            return false
        }
        
        // Agregar las tareas reordenadas al final del array
        tasks.append(contentsOf: orderedTasks)
    }
    
    /// Obtiene las tareas para una fecha específica en orden
    func getTasksForDate(_ date: Date) -> [TaskItem] {
        return tasks.filter { task in
            if task.taskType == .specific, let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    /// Actualiza el orden interno después de cambios
    private func updateTaskOrder() {
        // Asignar índices de orden basados en la posición actual
        for (index, _) in tasks.enumerated() {
            tasks[index].sortOrder = index
        }
        objectWillChange.send()
    }
    
    // MARK: - Category Methods
    
    func getCategoryForTask(_ task: TaskItem) -> TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    func addCategory(name: String, color: String, icon: String) {
        let category = TaskCategory(name: name, color: color, icon: icon)
        categories.append(category)
        saveCategories()
        objectWillChange.send()
    }
    
    func deleteCategory(categoryId: UUID) {
        // Remove category from all tasks first
        for i in 0..<tasks.count {
            if tasks[i].categoryId == categoryId {
                tasks[i].categoryId = nil
            }
        }
        
        // Remove the category
        categories.removeAll { $0.id == categoryId }
        
        saveTasks()
        saveCategories()
        objectWillChange.send()
    }
    
    func getTasksByCategory(categoryId: UUID?) -> [TaskItem] {
        if let categoryId = categoryId {
            return tasks.filter { $0.categoryId == categoryId }
        } else {
            return tasks.filter { $0.categoryId == nil }
        }
    }
    
    func updateTaskCategory(taskId: UUID, categoryId: UUID?) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].categoryId = categoryId
            saveTasks()
            objectWillChange.send()
        }
    }
    
    // MARK: - Gamification Methods
    
    private enum PointEvent {
        case taskCompleted
        case allTasksCompleted
        case streak(days: Int)
        
        var points: Int {
            switch self {
            case .taskCompleted: return 5
            case .allTasksCompleted: return 20
            case .streak(let days):
                if days >= 30 { return 50 }
                if days >= 7 { return 25 }
                if days >= 3 { return 10 }
                return 0
            }
        }
    }
    
    private func awardPoints(for event: PointEvent) {
        gamification.totalPoints += event.points
        // Solo actualizar streak y verificar día perfecto si es necesario
        if case .taskCompleted = event {
            updateStreak()
            checkForPerfectDay()
        }
    }
    
    private func updateStreak() {
        let key = todayKey()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayKey = formatter.string(from: yesterday)
        
        if gamification.lastTaskDate == yesterdayKey || gamification.lastTaskDate == key {
            if gamification.lastTaskDate != key {
                gamification.streak += 1
                gamification.maxStreak = max(gamification.maxStreak, gamification.streak)
                // Directamente otorgar puntos sin llamar a awardPoints para evitar recursión
                let streakPoints = PointEvent.streak(days: gamification.streak).points
                if streakPoints > 0 {
                    gamification.totalPoints += streakPoints
                }
            }
        } else if gamification.lastTaskDate != key {
            gamification.streak = 1
        }
        
        gamification.lastTaskDate = key
    }
    
    private func checkForPerfectDay() {
        let today = todayRecord
        let completedCount = today.statuses.filter { $0.completed }.count
        let totalCount = today.statuses.count
        
        if completedCount == totalCount && totalCount > 0 {
            // Directamente otorgar puntos sin llamar a awardPoints para evitar recursión
            gamification.totalPoints += PointEvent.allTasksCompleted.points
        }
    }
    
    private func checkAchievements() {
        for i in 0..<gamification.achievements.count {
            if !gamification.achievements[i].isUnlocked {
                let achievement = gamification.achievements[i]
                var shouldUnlock = false
                
                switch achievement.title {
                case "Primera Tarea":
                    shouldUnlock = true
                case "Racha de 3":
                    shouldUnlock = gamification.streak >= 3
                case "Racha de 7":
                    shouldUnlock = gamification.streak >= 7
                case "Constante":
                    shouldUnlock = gamification.streak >= 30
                case "Perfeccionista":
                    let today = todayRecord
                    let completed = today.statuses.filter { $0.completed }.count
                    shouldUnlock = completed == today.statuses.count && today.statuses.count > 0
                case "Productivo":
                    let today = todayRecord
                    let completed = today.statuses.filter { $0.completed }.count
                    shouldUnlock = completed >= 10
                case "Centenario":
                    shouldUnlock = gamification.totalPoints >= 100
                case "Milionario":
                    shouldUnlock = gamification.totalPoints >= 1000
                default:
                    break
                }
                
                if shouldUnlock {
                    gamification.achievements[i].isUnlocked = true
                    gamification.achievements[i].unlockedDate = Date()
                    gamification.totalPoints += achievement.points
                }
            }
        }
    }
    
    // MARK: - Daily Task Management
    
    func clearAllTasks() {
        // Clear all tasks
        tasks.removeAll()
        
        // Clear all records
        records.removeAll()
        
        // Reset gamification data
        gamification = GamificationData()
        
        // Save all changes
        saveTasks()
        saveRecords()
        saveGamification()
        objectWillChange.send()
    }
    
    func activateTaskForToday(taskId: UUID) {
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            if !records[rIndex].statuses.contains(where: { $0.taskId == taskId }) {
                records[rIndex].statuses.append(TaskStatus(taskId: taskId, completed: false, completedAt: nil))
                saveRecords()
                objectWillChange.send()
            }
        }
    }
    
    func deactivateTaskForToday(taskId: UUID) {
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            records[rIndex].statuses.removeAll { $0.taskId == taskId }
            saveRecords()
            objectWillChange.send()
        }
    }
    
    // MARK: - Task Status Methods
    
    func isTaskCompletedToday(_ taskId: UUID) -> Bool {
        let key = todayKey()
        guard let record = records.first(where: { $0.date == key }),
              let status = record.statuses.first(where: { $0.taskId == taskId }) else {
            return false
        }
        return status.completed
    }
    
    func isTaskActiveToday(_ taskId: UUID) -> Bool {
        let key = todayKey()
        guard let record = records.first(where: { $0.date == key }) else {
            return false
        }
        return record.statuses.contains { $0.taskId == taskId }
    }
    
    // MARK: - Computed Properties for UI
    
    var dailyRecords: [DailyRecord] {
        return records.sorted { $0.date > $1.date }
    }
    
    func completionRate(for dateString: String) -> Double {
        guard let record = records.first(where: { $0.date == dateString }) else {
            return 0.0
        }
        return record.completionRate
    }
    
    // MARK: - User Management
    
    func setUserName(_ name: String) {
        userName = name.isEmpty ? "Usuario" : name
        isFirstLaunch = false
        saveUserData()
        objectWillChange.send()
    }
    
    func resetUserData() {
        userName = "Usuario"
        isFirstLaunch = true
        saveUserData()
        objectWillChange.send()
    }
    
    // MARK: - Widget Integration
    
    private func updateWidgetData() {
        let widgetService = WidgetDataService.shared
        let currentTasks = tasks
        let currentRecord = todayRecord
        
        print("🔄 Actualizando widget - Tareas: \(currentTasks.count), Registros del día: \(currentRecord.statuses.count)")
        
        // Agregar más logs de depuración
        print("🔄 Tareas actuales:")
        for (index, task) in currentTasks.enumerated() {
            let isCompleted = currentRecord.statuses.first(where: { $0.taskId == task.id })?.completed ?? false
            print("   \(index + 1). \(task.title) - \(isCompleted ? "✓" : "○")")
        }
        
        widgetService.updateTaskProgress(tasks: currentTasks, todayRecord: currentRecord)
        
        print("🔄 Widget actualizado - Forzando recarga de timeline")
    }

    // MARK: - Habit Management Methods
    
    /// Agrega un nuevo hábito
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        
        // Crear streak tracking para el nuevo hábito
        let streak = HabitStreak(habitId: habit.id)
        habitStreaks.append(streak)
        
        // Crear entrada para hoy si no existe
        createHabitEntryForToday(habitId: habit.id)
        
        // Programar recordatorio si está configurado
        if habit.hasReminder, let reminderTime = habit.reminderTime {
            scheduleHabitReminder(habit: habit, time: reminderTime)
        }
        
        saveHabits()
        saveHabitStreaks()
        saveHabitEntries()
        objectWillChange.send()
    }
    
    /// Elimina un hábito y todos sus datos relacionados
    func deleteHabit(habitId: UUID) {
        // Cancelar notificaciones
        notificationService.cancelNotification(for: habitId)
        
        // Remover hábito
        habits.removeAll { $0.id == habitId }
        
        // Remover todas las entradas del hábito
        habitEntries.removeAll { $0.habitId == habitId }
        
        // Remover streak del hábito
        habitStreaks.removeAll { $0.habitId == habitId }
        
        saveHabits()
        saveHabitEntries()
        saveHabitStreaks()
        objectWillChange.send()
    }
    
    /// Actualiza el progreso de un hábito para hoy
    func updateHabitProgress(habitId: UUID, progress: Int) {
        let dateKey = todayKey()
        
        // Buscar entrada existente o crear una nueva
        if let index = habitEntries.firstIndex(where: { $0.habitId == habitId && $0.date == dateKey }) {
            habitEntries[index].progress = progress
            
            // Determinar si el hábito está completado
            if let habit = habits.first(where: { $0.id == habitId }) {
                let wasCompleted = habitEntries[index].isCompleted
                habitEntries[index].isCompleted = progress >= habit.target
                
                // Si se acaba de completar
                if !wasCompleted && habitEntries[index].isCompleted {
                    habitEntries[index].completedAt = Date()
                    updateHabitStreak(habitId: habitId, completed: true, date: dateKey)
                    
                    // Otorgar puntos por completar hábito
                    gamification.addPoints(10)
                    saveGamification()
                    
                    // Feedback háptico
                    HapticManager.shared.successImpact()
                }
            }
        } else {
            var entry = HabitEntry(habitId: habitId, date: dateKey, progress: progress)
            if let habit = habits.first(where: { $0.id == habitId }) {
                entry.isCompleted = progress >= habit.target
                if entry.isCompleted {
                    entry.completedAt = Date()
                    updateHabitStreak(habitId: habitId, completed: true, date: dateKey)
                    gamification.addPoints(10)
                    saveGamification()
                    HapticManager.shared.successImpact()
                }
            }
            habitEntries.append(entry)
        }
        
        saveHabitEntries()
        objectWillChange.send()
    }
    
    /// Marca un hábito como completado/no completado
    func toggleHabitCompletion(habitId: UUID) {
        let dateKey = todayKey()
        
        if let index = habitEntries.firstIndex(where: { $0.habitId == habitId && $0.date == dateKey }) {
            let wasCompleted = habitEntries[index].isCompleted
            habitEntries[index].isCompleted.toggle()
            
            if habitEntries[index].isCompleted {
                habitEntries[index].completedAt = Date()
                // Si el hábito tiene objetivo, marcarlo como alcanzado
                if let habit = habits.first(where: { $0.id == habitId }) {
                    habitEntries[index].progress = habit.target
                }
                updateHabitStreak(habitId: habitId, completed: true, date: dateKey)
                gamification.addPoints(10)
                HapticManager.shared.successImpact()
            } else {
                habitEntries[index].completedAt = nil
                habitEntries[index].progress = 0
                updateHabitStreak(habitId: habitId, completed: false, date: dateKey)
                HapticManager.shared.lightImpact()
            }
            
            saveHabitEntries()
            saveGamification()
            objectWillChange.send()
        } else {
            // Crear nueva entrada
            var entry = HabitEntry(habitId: habitId, date: dateKey)
            entry.isCompleted = true
            entry.completedAt = Date()
            if let habit = habits.first(where: { $0.id == habitId }) {
                entry.progress = habit.target
            }
            habitEntries.append(entry)
            
            updateHabitStreak(habitId: habitId, completed: true, date: dateKey)
            gamification.addPoints(10)
            saveHabitEntries()
            saveGamification()
            HapticManager.shared.successImpact()
            objectWillChange.send()
        }
    }
    
    /// Actualiza el streak de un hábito
    private func updateHabitStreak(habitId: UUID, completed: Bool, date: String) {
        if let index = habitStreaks.firstIndex(where: { $0.habitId == habitId }) {
            habitStreaks[index].updateStreak(completed: completed, date: date)
        } else {
            var newStreak = HabitStreak(habitId: habitId)
            newStreak.updateStreak(completed: completed, date: date)
            habitStreaks.append(newStreak)
        }
        saveHabitStreaks()
    }
    
    /// Crea entrada de hábito para hoy si no existe
    private func createHabitEntryForToday(habitId: UUID) {
        let dateKey = todayKey()
        let exists = habitEntries.contains { $0.habitId == habitId && $0.date == dateKey }
        
        if !exists {
            let entry = HabitEntry(habitId: habitId, date: dateKey)
            habitEntries.append(entry)
            saveHabitEntries()
        }
    }
    
    /// Programa recordatorio para un hábito
    private func scheduleHabitReminder(habit: Habit, time: Date) {
        // Implementar notificación específica para hábitos
        // Por ahora usamos el sistema existente
        if habit.hasReminder, let reminderTime = habit.reminderTime {
            notificationService.scheduleHabitReminder(habit: habit, at: reminderTime)
        }
    }
    
    // MARK: - Habit Computed Properties
    
    /// Obtiene el progreso de un hábito para hoy
    func getHabitProgressToday(habitId: UUID) -> Int {
        let dateKey = todayKey()
        return habitEntries.first { $0.habitId == habitId && $0.date == dateKey }?.progress ?? 0
    }
    
    /// Verifica si un hábito está completado hoy
    func isHabitCompletedToday(habitId: UUID) -> Bool {
        let dateKey = todayKey()
        return habitEntries.first { $0.habitId == habitId && $0.date == dateKey }?.isCompleted ?? false
    }
    
    /// Obtiene el streak actual de un hábito
    func getHabitStreak(habitId: UUID) -> HabitStreak? {
        return habitStreaks.first { $0.habitId == habitId }
    }
    
    /// Obtiene las entradas de un hábito para los últimos N días
    func getHabitEntries(habitId: UUID, days: Int = 30) -> [HabitEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return habitEntries.filter { entry in
            guard entry.habitId == habitId,
                  let entryDate = dateFormatter.date(from: entry.date) else { return false }
            return entryDate >= startDate && entryDate <= endDate
        }.sorted { $0.date > $1.date }
    }
    
    /// Obtiene estadísticas de hábitos para hoy
    var todayHabitStats: (total: Int, completed: Int, percentage: Double) {
        let activeHabits = habits.filter { $0.isActive }
        let dateKey = todayKey()
        let completedCount = habitEntries.filter {
            $0.date == dateKey && $0.isCompleted
        }.count
        
        let total = activeHabits.count
        let percentage = total > 0 ? Double(completedCount) / Double(total) : 0.0
        
        return (total: total, completed: completedCount, percentage: percentage)
    }
    
    /// Obtiene hábitos activos
    var activeHabits: [Habit] {
        return habits.filter { $0.isActive }
    }
}

struct GamificationData: Codable {
    var totalPoints: Int = 0
    var level: Int = 1
    var streak: Int = 0
    var maxStreak: Int = 0
    var lastTaskDate: String?
    var achievements: [Achievement] = Achievement.defaultAchievements
    
    mutating func addPoints(_ pointsToAdd: Int) {
        totalPoints += pointsToAdd
        updateLevel()
    }
    
    private mutating func updateLevel() {
        let newLevel = (totalPoints / 100) + 1
        if newLevel > level {
            level = newLevel
        }
    }
}

struct Achievement: Codable {
    var title: String
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var points: Int
    
    static var defaultAchievements: [Achievement] {
        return [
            Achievement(title: "Primera Tarea", points: 10),
            Achievement(title: "Racha de 3", points: 15),
            Achievement(title: "Racha de 7", points: 25),
            Achievement(title: "Constante", points: 50),
            Achievement(title: "Perfeccionista", points: 100),
            Achievement(title: "Productivo", points: 20),
            Achievement(title: "Centenario", points: 30),
            Achievement(title: "Milionario", points: 50)
        ]
    }
}

struct UserData: Codable {
    var name: String
    var isFirstLaunch: Bool
}
