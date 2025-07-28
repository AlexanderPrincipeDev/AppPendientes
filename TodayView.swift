import SwiftUI

struct TodayView: View {
    @ObservedObject var model: ChoreModel

    var body: some View {
        List {
            if model.todayRecord.statuses.isEmpty {
                ContentUnavailableView(
                    "No hay tareas para hoy",
                    systemImage: "checkmark.circle",
                    description: Text("Activa las tareas que quieras realizar hoy desde la pestaña Tareas")
                )
            } else {
                ForEach(model.todayRecord.statuses, id: \.taskId) { status in
                    if let task = model.tasks.first(where: { $0.id == status.taskId }) {
                        HStack {
                            Image(systemName: status.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(status.completed ? .green : .gray)
                                .font(.system(size: 22))
                                .contentTransition(.symbolEffect(.replace))
                            
                            Text(task.title)
                                .font(.body)
                                .strikethrough(status.completed, color: .gray)
                                .foregroundStyle(status.completed ? .secondary : .primary)
                                .animation(.easeInOut, value: status.completed)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { 
                            withAnimation {
                                model.toggle(taskId: task.id)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Hoy")
        .navigationBarTitleDisplayMode(.large)
        .animation(.default, value: model.todayRecord.statuses)
    }
}
