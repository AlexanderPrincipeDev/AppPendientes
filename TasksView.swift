import SwiftUI

struct TasksView: View {
    @ObservedObject var model: ChoreModel
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(model.tasks) { task in
                HStack {
                    Text(task.title)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: {
                            model.todayRecord.statuses.contains { $0.taskId == task.id }
                        },
                        set: { isOn in
                            if isOn {
                                model.activateTaskForToday(taskId: task.id)
                            } else {
                                model.deactivateTaskForToday(taskId: task.id)
                            }
                        }
                    ))
                }
            }
        }
        .navigationTitle("Tareas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskView { model.addTask(title: $0) }
        }
    }
}
