import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var categoryId: UUID?

    init(title: String, categoryId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.categoryId = categoryId
    }
}
