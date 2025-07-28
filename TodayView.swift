import SwiftUI

struct TodayView: View {
    @ObservedObject var model: ChoreModel

    var body: some View {
        List {
            ForEach(model.todayRecord.statuses, id: \.taskId) { status in
                HStack {
                    if let task = model.tasks.first(where: { $0.id == status.taskId }) {
                        Text(task.title)
                        Spacer()
                        Image(systemName: status.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(status.completed ? .green : .gray)
                            .onTapGesture { model.toggle(taskId: task.id) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Hoy")
    }
}
