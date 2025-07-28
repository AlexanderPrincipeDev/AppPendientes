import SwiftUI

struct TasksView: View {
    @ObservedObject var model: ChoreModel
    @State private var showingAdd = false
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: TaskItem?
    @State private var selectedCategoryFilter: String = "Todas"

    var filteredTasks: [TaskItem] {
        if selectedCategoryFilter == "Todas" {
            return model.tasks
        } else if selectedCategoryFilter == "Sin categoría" {
            return model.tasks.filter { task in
                task.categoryId == nil
            }
        } else {
            let selectedCategory = model.categories.first { $0.name == selectedCategoryFilter }
            return model.tasks.filter { task in
                task.categoryId == selectedCategory?.id
            }
        }
    }
    
    // Helper methods to simplify Toggle binding
    private func isTaskActive(_ task: TaskItem) -> Bool {
        return model.todayRecord.statuses.contains { $0.taskId == task.id }
    }
    
    private func toggleTaskActivation(_ task: TaskItem, newValue: Bool) {
        if newValue {
            // Add task to today's record if not already there
            if !model.isTaskActiveToday(task.id) {
                model.activateTaskForToday(taskId: task.id)
            }
        } else {
            // Remove task from today's record
            model.deactivateTaskForToday(taskId: task.id)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            CategoryFilterSection(
                categories: model.categories,
                selectedFilter: $selectedCategoryFilter
            )
            
            TaskListSection(
                tasks: filteredTasks,
                model: model,
                isTaskActive: isTaskActive,
                toggleTaskActivation: toggleTaskActivation,
                deleteTask: deleteTask
            )
        }
        .navigationTitle("Tareas")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskView()
                .environmentObject(model)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .alert("Eliminar Tarea", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
            Button("Cancelar", role: .cancel) {
                taskToDelete = nil
            }
            if task != nil {
                Button("Eliminar", role: .destructive) {
                    model.deleteTask(taskId: task!.id)
                    taskToDelete = nil
                }
            } else {
                Button("Limpiar Todo", role: .destructive) {
                    model.clearAllTasks()
                    taskToDelete = nil
                }
            }
        } message: { task in
            if task != nil {
                Text("¿Estás seguro de que quieres eliminar '\(task!.title)'? Esta acción no se puede deshacer.")
            } else {
                Text("¿Estás seguro de que quieres eliminar TODAS las tareas? Esta acción no se puede deshacer y también eliminará todo el historial.")
            }
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            taskToDelete = filteredTasks[index]
            showingDeleteAlert = true
        }
    }
}

// MARK: - Category Filter Section
struct CategoryFilterSection: View {
    let categories: [TaskCategory]
    @Binding var selectedFilter: String
    
    private var sortedCategories: [TaskCategory] {
        let priorityCategories = ["Casa", "Trabajo", "Personal", "Salud"]
        let priorityItems = categories.filter { priorityCategories.contains($0.name) }
        let otherItems = categories.filter { !priorityCategories.contains($0.name) }
        return priorityItems + otherItems
    }
    
    private var allFilterOptions: [(title: String, icon: String, color: Color)] {
        var options: [(title: String, icon: String, color: Color)] = [
            ("Todas", "list.bullet", .blue),
            ("Sin categoría", "circle", .gray)
        ]
        
        for category in sortedCategories {
            options.append((category.name, category.icon, category.swiftUIColor))
        }
        
        return options
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: 6)
        ], spacing: 6) {
            ForEach(allFilterOptions, id: \.title) { option in
                CategoryFilterChip(
                    title: option.title,
                    icon: option.icon,
                    color: option.color,
                    isSelected: selectedFilter == option.title
                ) {
                    selectedFilter = option.title
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

// MARK: - Task List Section
struct TaskListSection: View {
    let tasks: [TaskItem]
    let model: ChoreModel
    let isTaskActive: (TaskItem) -> Bool
    let toggleTaskActivation: (TaskItem, Bool) -> Void
    let deleteTask: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    model: model,
                    isTaskActive: isTaskActive,
                    toggleTaskActivation: toggleTaskActivation
                )
            }
            .onDelete(perform: deleteTask)
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    let model: ChoreModel
    let isTaskActive: (TaskItem) -> Bool
    let toggleTaskActivation: (TaskItem, Bool) -> Void
    
    var body: some View {
        HStack {
            CategoryIndicatorView(task: task, model: model)
            
            TaskInfoView(task: task, model: model)
            
            Spacer()
            
            TaskToggleView(
                task: task,
                isTaskActive: isTaskActive,
                toggleTaskActivation: toggleTaskActivation
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Indicator View
struct CategoryIndicatorView: View {
    let task: TaskItem
    let model: ChoreModel
    
    var body: some View {
        if let category = model.getCategoryForTask(task) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundStyle(category.swiftUIColor)
                .frame(width: 20)
        } else {
            Image(systemName: "circle")
                .font(.system(size: 16))
                .foregroundStyle(.gray)
                .frame(width: 20)
        }
    }
}

// MARK: - Task Info View
struct TaskInfoView: View {
    let task: TaskItem
    let model: ChoreModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(.body)
            
            if let category = model.getCategoryForTask(task) {
                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(category.swiftUIColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(category.swiftUIColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

// MARK: - Task Toggle View
struct TaskToggleView: View {
    let task: TaskItem
    let isTaskActive: (TaskItem) -> Bool
    let toggleTaskActivation: (TaskItem, Bool) -> Void
    
    var body: some View {
        Toggle("Tarea", isOn: Binding(
            get: { isTaskActive(task) },
            set: { newValue in toggleTaskActivation(task, newValue) }
        ))
        .labelsHidden()
        .tint(.blue)
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isSelected ? 0 : 0.5)
                    .opacity(isSelected ? 0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
