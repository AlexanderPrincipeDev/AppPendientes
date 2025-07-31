import Foundation

class DataStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    enum StorageError: Error {
        case saveFailed(String)
        case loadFailed(String)
    }

    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Generic Save/Load Methods
    private func save<T: Codable>(_ object: T, to fileName: String) throws {
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        } catch {
            throw StorageError.saveFailed("\(fileName): \(error)")
        }
    }

    private func load<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw StorageError.loadFailed("\(fileName): \(error)")
        }
    }

    // MARK: - Specific Data Methods
    func saveTasks(_ tasks: [TaskItem]) throws {
        try save(tasks, to: "tasks.json")
    }

    func saveRecords(_ records: [DailyRecord]) throws {
        try save(records, to: "records.json")
    }

    func saveCategories(_ categories: [TaskCategory]) throws {
        try save(categories, to: "categories.json")
    }

    func saveGamification(_ data: GamificationData) throws {
        try save(data, to: "gamification.json")
    }

    func saveUserData(_ data: UserData) throws {
        try save(data, to: "userData.json")
    }

    func loadTasks() throws -> [TaskItem] {
        try load([TaskItem].self, from: "tasks.json")
    }

    func loadRecords() throws -> [DailyRecord] {
        try load([DailyRecord].self, from: "records.json")
    }

    func loadCategories() throws -> [TaskCategory] {
        try load([TaskCategory].self, from: "categories.json")
    }

    func loadGamification() throws -> GamificationData {
        try load(GamificationData.self, from: "gamification.json")
    }

    func loadUserData() throws -> UserData {
        try load(UserData.self, from: "userData.json")
    }
}