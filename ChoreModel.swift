import Foundation
import SwiftUI

@MainActor
class ChoreModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var records: [DailyRecord] = []

    private let tasksFile = "tasks.json"
    private let recordsFile = "records.json"

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

    func loadAll() {
        if let data = try? Data(contentsOf: tasksURL),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        } else {
            tasks = ["Tender la cama","Barrer la casa","Lavar los platos","Tender la ropa","Lavar ropa"].map { TaskItem(title: $0) }
            saveTasks()
        }
        if let data = try? Data(contentsOf: recordsURL),
           let decoded = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            records = decoded
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
        records[rIndex].statuses[sIndex].completed.toggle()
        saveRecords()
        objectWillChange.send()
    }

    func addTask(title: String) {
        let item = TaskItem(title: title)
        tasks.append(item)
        saveTasks()
        let key = todayKey()
        if let rIndex = records.firstIndex(where: { $0.date == key }) {
            records[rIndex].statuses.append(TaskStatus(taskId: item.id, completed: false))
        }
        saveRecords()
        objectWillChange.send()
    }

    func isTaskActiveToday(taskId: UUID) -> Bool {
        let key = todayKey()
        guard let rIndex = records.firstIndex(where: { $0.date == key }) else { return false }
        return records[rIndex].statuses.contains { $0.taskId == taskId }
    }

    func activateTaskForToday(taskId: UUID) {
        let key = todayKey()
        guard let rIndex = records.firstIndex(where: { $0.date == key }) else { return }
        if !records[rIndex].statuses.contains(where: { $0.taskId == taskId }) {
            records[rIndex].statuses.append(TaskStatus(taskId: taskId, completed: false))
            saveRecords()
            objectWillChange.send()
        }
    }

    func deactivateTaskForToday(taskId: UUID) {
        let key = todayKey()
        guard let rIndex = records.firstIndex(where: { $0.date == key }) else { return }
        records[rIndex].statuses.removeAll { $0.taskId == taskId }
        saveRecords()
        objectWillChange.send()
    }
}
