import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var categoryId: UUID?
    var hasReminder: Bool
    var reminderTime: Date?
    var repeatDaily: Bool

    init(title: String, categoryId: UUID? = nil, hasReminder: Bool = false, reminderTime: Date? = nil, repeatDaily: Bool = true) {
        self.id = UUID()
        self.title = title
        self.categoryId = categoryId
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
        self.repeatDaily = repeatDaily
    }
}
