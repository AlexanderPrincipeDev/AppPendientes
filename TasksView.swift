import SwiftUI

struct TasksView: View {
    @ObservedObject var model: ChoreModel
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(model.tasks) { task in
                HStack {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { model.todayRecord.statuses.contains { $0.taskId == task.id } },
                        set: { isOn in
                            if isOn {
                                withAnimation {
                                    model.activateTaskForToday(taskId: task.id)
                                }
                            } else {
                                withAnimation {
                                    model.deactivateTaskForToday(taskId: task.id)
                                }
                            }
                        }
                    ))
                    .tint(.blue)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color(.systemBackground))
            }
        }
        .navigationTitle("Tareas")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskView { model.addTask(title: $0) }
        }
    }
}
