import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String

    init(title: String) {
        self.id = UUID()
        self.title = title
    }
}
