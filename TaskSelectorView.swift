import SwiftUI

struct TaskSelectorView: View {
    @Binding var selectedTask: TaskItem?
    let onTaskSelected: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var choreModel: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchSection
                
                // Task list
                taskListSection
            }
            .navigationTitle("Seleccionar Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sin Tarea") {
                        selectedTask = nil
                        onTaskSelected()
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentAccentColor)
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                TextField("Buscar tareas...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("Limpiar") {
                        searchText = ""
                        HapticManager.shared.lightImpact()
                    }
                    .font(.caption)
                    .foregroundStyle(themeManager.currentAccentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.themeColors.surface)
            
            Divider()
        }
    }
    
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedTasks.keys.sorted(), id: \.self) { categoryName in
                        if let tasks = groupedTasks[categoryName], !tasks.isEmpty {
                            TaskCategorySection(
                                categoryName: categoryName,
                                tasks: tasks,
                                selectedTask: $selectedTask,
                                onTaskSelected: {
                                    onTaskSelected()
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.themeColors.secondary)
            
            Text("No hay tareas disponibles")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            Text("Crea algunas tareas primero para poder vincularlas con tus sesiones Pomodoro.")
                .font(.subheadline)
                .foregroundStyle(themeManager.themeColors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private var filteredTasks: [TaskItem] {
        let pendingTasks = choreModel.tasks.filter { task in
            !choreModel.isTaskCompletedToday(task.id)
        }
        
        if searchText.isEmpty {
            return pendingTasks
        } else {
            return pendingTasks.filter { task in
                let titleMatch = task.title.localizedCaseInsensitiveContains(searchText)
                let categoryMatch = choreModel.getCategoryForTask(task)?.name.localizedCaseInsensitiveContains(searchText) ?? false
                return titleMatch || categoryMatch
            }
        }
    }
    
    private var groupedTasks: [String: [TaskItem]] {
        Dictionary(grouping: filteredTasks) { task in
            choreModel.getCategoryForTask(task)?.name ?? "Sin Categoría"
        }
    }
}

struct TaskCategorySection: View {
    let categoryName: String
    let tasks: [TaskItem]
    @Binding var selectedTask: TaskItem?
    let onTaskSelected: () -> Void
    @EnvironmentObject var choreModel: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack {
                Text(categoryName)
                    .font(.headline)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.themeColors.surface)
                    )
            }
            
            // Tasks
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskSelectorRow(
                        task: task,
                        isSelected: selectedTask?.id == task.id,
                        onTap: {
                            selectedTask = task
                            HapticManager.shared.selection()
                            onTaskSelected()
                        }
                    )
                }
            }
        }
        .padding(.bottom, 16)
    }
}

struct TaskSelectorRow: View {
    let task: TaskItem
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var choreModel: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    private var category: TaskCategory? {
        choreModel.getCategoryForTask(task)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Task icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(categoryColor)
                }
                
                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.themeColors.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let category = category {
                            Text(category.name)
                                .font(.caption)
                                .foregroundStyle(categoryColor)
                        }
                        
                        if task.priority != .medium {
                            Text(task.priority.rawValue)
                                .font(.caption)
                                .foregroundStyle(priorityColor)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeManager.currentAccentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.currentAccentColor.opacity(0.1) : themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentAccentColor.opacity(0.3) : themeManager.themeColors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        switch category?.name.lowercased() {
        case "casa": return .orange
        case "trabajo": return .blue
        case "personal": return .purple
        case "salud": return .red
        case "ejercicio": return .green
        case "estudio": return .indigo
        case "compras": return .yellow
        default: return themeManager.currentAccentColor
        }
    }
    
    private var categoryIcon: String {
        switch category?.name.lowercased() {
        case "casa": return "house.fill"
        case "trabajo": return "briefcase.fill"
        case "personal": return "person.fill"
        case "salud": return "heart.fill"
        case "ejercicio": return "figure.run"
        case "estudio": return "book.fill"
        case "compras": return "cart.fill"
        default: return "list.bullet"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    TaskSelectorView(selectedTask: .constant(nil)) {
        // Preview action
    }
    .environmentObject(ChoreModel())
}
