import SwiftUI

struct TodayView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var showingAddTask = false
    
    private var todayTasks: [TaskItem] {
        let activeTaskIds = Set(model.todayRecord.statuses.map { $0.taskId })
        return model.tasks.filter { activeTaskIds.contains($0.id) }
    }
    
    private var completedTasks: [TaskItem] {
        todayTasks.filter { model.isTaskCompletedToday($0.id) }
    }
    
    private var pendingTasks: [TaskItem] {
        todayTasks.filter { !model.isTaskCompletedToday($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with progress
                    TodayHeaderView()
                    
                    // Quick add task
                    QuickAddTaskView()
                    
                    // Pending tasks
                    if !pendingTasks.isEmpty {
                        TaskSection(
                            title: "Pendientes",
                            tasks: pendingTasks,
                            isCompleted: false
                        )
                    }
                    
                    // Completed tasks
                    if !completedTasks.isEmpty {
                        TaskSection(
                            title: "Completadas",
                            tasks: completedTasks,
                            isCompleted: true
                        )
                    }
                    
                    // Empty state
                    if todayTasks.isEmpty {
                        EmptyTodayView()
                    }
                }
                .padding()
            }
            .navigationTitle("Hoy")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh data if needed
            }
        }
    }
}

// MARK: - Today Header
struct TodayHeaderView: View {
    @EnvironmentObject var model: ChoreModel
    
    private var todayRecord: DailyRecord {
        model.todayRecord
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().dayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(Date().shortDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: todayRecord.completionRate)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: todayRecord.completionRate)
                    
                    Text("\(Int(todayRecord.completionRate * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progreso del día")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(todayRecord.completedCount) de \(todayRecord.totalCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: todayRecord.completionRate)
                    .tint(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Add Task
struct QuickAddTaskView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var newTaskTitle = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            TextField("Agregar tarea rápida...", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onSubmit {
                    addTask()
                }
            
            Button {
                addTask()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        model.addTask(title: title)
        
        // Get the newly created task and activate it for today
        if let newTask = model.tasks.last {
            model.activateTaskForToday(taskId: newTask.id)
        }
        
        newTaskTitle = ""
        isTextFieldFocused = false
    }
}

// MARK: - Task Section
struct TaskSection: View {
    let title: String
    let tasks: [TaskItem]
    let isCompleted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            
            ForEach(tasks) { task in
                TodayTaskRow(task: task, isCompleted: isCompleted)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Today Task Row
struct TodayTaskRow: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    let isCompleted: Bool
    
    private var category: TaskCategory? {
        model.getCategoryForTask(task)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button {
                model.toggle(taskId: task.id)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Category icon
            if let category = category {
                Image(systemName: category.icon)
                    .foregroundStyle(category.swiftUIColor)
                    .frame(width: 20)
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                
                if let category = category {
                    Text(category.name)
                        .font(.caption)
                        .foregroundStyle(category.swiftUIColor)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            model.toggle(taskId: task.id)
        }
    }
}

// MARK: - Empty Today View
struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.max")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("¡Buen día!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("No tienes tareas activas para hoy.\nPuedes agregar una tarea rápida arriba o ir a la pestaña Tareas.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
