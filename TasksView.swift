import SwiftUI

struct TasksView: View {
    @ObservedObject var model: ChoreModel
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(model.tasks) { task in
                TaskRowView(task: task, model: model)
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

struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var model: ChoreModel
    @State private var isEnabled: Bool = false
    
    var body: some View {
        HStack {
            Text(task.title)
            Spacer()
            Toggle("", isOn: $isEnabled)
                .onChange(of: isEnabled) { newValue in
                    model.toggle(taskId: task.id)
                }
        }
    }
}
