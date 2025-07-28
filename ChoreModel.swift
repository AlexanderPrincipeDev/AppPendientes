import Foundation
import SwiftUI

@MainActor
class ChoreModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var records: [DailyRecord] = []
    @Published var gamification = GamificationData()
    @Published var categories: [TaskCategory] = []

    private let tasksFile = "tasks.json"
    private let recordsFile = "records.json"
    private let gamificationFile = "gamification.json"
    private let categoriesFile = "categories.json"

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
            // Asignar categorías predeterminadas a las tareas iniciales
            let houseCategory = categories.first { $0.name == "Casa" }
            tasks = ["Tender la cama","Barrer la casa","Lavar los platos","Tender la ropa","Lavar ropa"].map {
                TaskItem(title: $0, categoryId: houseCategory?.id)
            }
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
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            try? data.write(to: tasksURL)
        }
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
        }
        
        saveRecords()
        saveGamification()
        objectWillChange.send()
    }

    func addTask(title: String, categoryId: UUID? = nil) {
        let item = TaskItem(title: title, categoryId: categoryId)
        tasks.append(item)
        saveTasks()
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            records[rIndex].statuses.append(TaskStatus(taskId: item.id, completed: false, completedAt: nil))
        }
        saveRecords()
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
    
    func deleteTask(taskId: UUID) {
        // Remove from tasks
        tasks.removeAll { $0.id == taskId }
        
        // Remove from all records
        for i in 0..<records.count {
            records[i].statuses.removeAll { $0.taskId == taskId }
        }
        
        saveTasks()
        saveRecords()
        objectWillChange.send()
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
