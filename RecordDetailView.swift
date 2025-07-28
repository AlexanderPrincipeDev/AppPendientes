import SwiftUI

struct RecordDetailView: View {
    let record: DailyRecord
    @ObservedObject var model: ChoreModel
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        List {
            ForEach(record.statuses, id: \.taskId) { status in
                if let task = model.tasks.first(where: { $0.id == status.taskId }) {
                    HStack {
                        Text(task.title)
                        Spacer()
                        if status.completed {
                            if let completedAt = status.completedAt {
                                Text(timeFormatter.string(from: completedAt))
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            }
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle(record.date)
    }
}
