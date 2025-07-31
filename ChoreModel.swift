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
    @Published var lastError: String?

    private let notificationService = NotificationService.shared
    private let storage = DataStorage()
    private let gamificationManager = GamificationManager()

    private func handleError(_ error: Error, message: String) {
        print("\(message): \(error)")
        lastError = message
    }

    init() {
        loadAll()
    }

    func loadAll() {
        do {
            categories = try storage.loadCategories()
        } catch {
            categories = TaskCategory.defaultCategories
            handleError(error, message: "Failed to load categories")
            do { try storage.saveCategories(categories) } catch { handleError(error, message: "Failed to save default categories") }
        }

        do {
            tasks = try storage.loadTasks()
        } catch {
            tasks = []
            handleError(error, message: "Failed to load tasks")
            do { try storage.saveTasks(tasks) } catch { handleError(error, message: "Failed to save empty tasks") }
        }

        do {
            records = try storage.loadRecords()
        } catch {
            records = []
            handleError(error, message: "Failed to load records")
        }

        do {
            gamification = try storage.loadGamification()
        } catch {
            gamification = GamificationData()
            handleError(error, message: "Failed to load gamification data")
        }

        do {
            let userData = try storage.loadUserData()
            userName = userData.name
            isFirstLaunch = userData.isFirstLaunch
        } catch {
            handleError(error, message: "Failed to load user data")
        }

        // Limpiar tareas huérfanas después de cargar los datos
        cleanupOrphanedTasks()
    }

    func saveTasks() {
        do { try storage.saveTasks(tasks) } catch { handleError(error, message: "Error saving tasks") }
    }
    func saveRecords() {
        do { try storage.saveRecords(records) } catch { handleError(error, message: "Error saving records") }
    }
    func saveGamification() {
        do { try storage.saveGamification(gamification) } catch { handleError(error, message: "Error saving gamification") }
    }
    func saveCategories() {
        do { try storage.saveCategories(categories) } catch { handleError(error, message: "Error saving categories") }
    }
    func saveUserData() {
        let userData = UserData(name: userName, isFirstLaunch: isFirstLaunch)
        do { try storage.saveUserData(userData) } catch { handleError(error, message: "Error saving user data") }
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
            gamificationManager.awardTaskCompleted(&gamification)
            
            // Check if all tasks are now completed
            checkForDayCompletion()
        }
        
        saveRecords()
        saveGamification()
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
            gamificationManager.awardAllTasksCompleted(&gamification)
            saveGamification()
        }
    }

    func addTask(title: String, categoryId: UUID? = nil, hasReminder: Bool = false, reminderTime: Date? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let shouldSetReminder = hasReminder && reminderTime != nil
        let item = TaskItem(title: trimmed, categoryId: categoryId, hasReminder: shouldSetReminder, reminderTime: reminderTime)
        tasks.append(item)
        saveTasks()

        // Schedule notification if reminder is set
        if shouldSetReminder, let reminderTime = reminderTime {
            notificationService.scheduleTaskReminder(for: item, at: reminderTime, repeatDaily: item.repeatDaily)
        }
        
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            records[rIndex].statuses.append(TaskStatus(taskId: item.id, completed: false, completedAt: nil))
        }
        saveRecords()
        objectWillChange.send()
    }
    
    func updateTaskReminder(taskId: UUID, hasReminder: Bool, reminderTime: Date? = nil, repeatDaily: Bool = true) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }

        // Cancel existing notification
        notificationService.cancelNotification(for: taskId)

        tasks[index].repeatDaily = repeatDaily

        if hasReminder {
            guard let reminderTime = reminderTime else { return }
            tasks[index].hasReminder = true
            tasks[index].reminderTime = reminderTime
            notificationService.scheduleTaskReminder(for: tasks[index], at: reminderTime, repeatDaily: repeatDaily)
        } else {
            tasks[index].hasReminder = false
            tasks[index].reminderTime = nil
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
        objectWillChange.send()
    }
    
    func scheduleDailyReminder(at time: Date) {
        let incompleteTasks = getIncompleteTasks()
        if !incompleteTasks.isEmpty {
            notificationService.scheduleTasksDailyReminder(tasks: incompleteTasks, at: time, userName: userName)
        }
    }
    
    private func getIncompleteTasks() -> [TaskItem] {
        let todayRecord = self.todayRecord
        return tasks.filter { task in
            let status = todayRecord.statuses.first { $0.taskId == task.id }
            return status?.completed != true
        }
    }
    
    // MARK: - Category Methods
    
    func getCategoryForTask(_ task: TaskItem) -> TaskCategory? {
        guard let categoryId = task.categoryId else { return nil }
        return categories.first { $0.id == categoryId }
    }
    
    func addCategory(name: String, color: String, icon: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = TaskCategory(name: trimmed, color: color, icon: icon)
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
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmed.isEmpty ? "Usuario" : trimmed
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
}
