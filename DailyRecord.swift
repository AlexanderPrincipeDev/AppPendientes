import Foundation

struct TaskStatus: Codable, Hashable {
    let taskId: UUID
    var completed: Bool
    var completedAt: Date?  // Nueva propiedad para guardar la hora
}

struct DailyRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: String  // "yyyy-MM-dd"
    var statuses: [TaskStatus]

    init(date: String, statuses: [TaskStatus]) {
        self.id = UUID()
        self.date = date
        self.statuses = statuses
    }
    
    // Computed properties for UI convenience
    var completedCount: Int {
        statuses.filter { $0.completed }.count
    }
    
    var totalCount: Int {
        statuses.count
    }
    
    var completionRate: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    }
}
