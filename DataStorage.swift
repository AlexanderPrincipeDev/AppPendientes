import Foundation

class DataStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Generic Save/Load Methods
    private func save<T: Codable>(_ object: T, to fileName: String) {
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        } catch {
            print("Failed to save \(fileName): \(error)")
        }
    }
    
    private func load<T: Codable>(_ type: T.Type, from fileName: String) -> T? {
        let url = documentsDirectory.appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Specific Data Methods
    func save(_ tasks: [TaskItem]) {
        save(tasks, to: "tasks.json")
    }
    
    func save(_ records: [DailyRecord]) {
        save(records, to: "records.json")
    }
    
    func save(_ categories: [TaskCategory]) {
        save(categories, to: "categories.json")
    }
    
    func loadTasks() -> [TaskItem] {
        return load([TaskItem].self, from: "tasks.json") ?? []
    }
    
    func loadRecords() -> [DailyRecord] {
        return load([DailyRecord].self, from: "records.json") ?? []
    }
    
    func loadCategories() -> [TaskCategory] {
        return load([TaskCategory].self, from: "categories.json") ?? TaskCategory.defaultCategories
    }
}