import SwiftUI

struct TasksView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var showingAdd = false
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: TaskItem?
    @State private var selectedCategoryFilter: String = "Todas"
    @State private var searchText = ""
    @State private var showingEditTask: TaskItem?
    
    var filteredTasks: [TaskItem] {
        var tasks = model.tasks
        
        // Filter by category
        if selectedCategoryFilter != "Todas" {
            if selectedCategoryFilter == "Sin categoría" {
                tasks = tasks.filter { $0.categoryId == nil }
            } else {
                let selectedCategory = model.categories.first { $0.name == selectedCategoryFilter }
                tasks = tasks.filter { $0.categoryId == selectedCategory?.id }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return tasks.sorted { first, second in
            // Sort by category first, then by title
            let firstCategory = model.getCategoryForTask(first)?.name ?? "ZZZ"
            let secondCategory = model.getCategoryForTask(second)?.name ?? "ZZZ"
            
            if firstCategory != secondCategory {
                return firstCategory < secondCategory
            }
            return first.title < second.title
        }
    }
    
    private var sortedCategories: [TaskCategory] {
        let priorityCategories = ["Casa", "Trabajo", "Personal", "Salud"]
        let priorityItems = model.categories.filter { priorityCategories.contains($0.name) }
        let otherItems = model.categories.filter { !priorityCategories.contains($0.name) }
        return priorityItems + otherItems
    }
    
    private var taskCount: (total: Int, byCategory: [String: Int]) {
        var byCategory: [String: Int] = [:]
        
        // Count all tasks
        byCategory["Todas"] = model.tasks.count
        
        // Count uncategorized tasks
        let uncategorizedCount = model.tasks.filter { $0.categoryId == nil }.count
        if uncategorizedCount > 0 {
            byCategory["Sin categoría"] = uncategorizedCount
        }
        
        // Count tasks by category
        for category in model.categories {
            let count = model.tasks.filter { $0.categoryId == category.id }.count
            if count > 0 {
                byCategory[category.name] = count
            }
        }
        
        return (model.tasks.count, byCategory)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Stats Summary
                TasksHeaderSection(
                    totalTasks: taskCount.total,
                    filteredCount: filteredTasks.count,
                    selectedFilter: selectedCategoryFilter,
                    categoryCount: model.categories.count
                )
                
                // Search Bar
                if !model.tasks.isEmpty {
                    SearchBarSection(searchText: $searchText)
                }
                
                // Category Filter Pills
                if !model.categories.isEmpty {
                    CategoryFilterSection(
                        selectedFilter: $selectedCategoryFilter,
                        categories: sortedCategories,
                        taskCounts: taskCount.byCategory
                    )
                }
                
                // Main Content
                if model.tasks.isEmpty {
                    EmptyAllTasksView {
                        showingAdd = true
                    }
                } else if filteredTasks.isEmpty {
                    EmptyFilteredTasksView(
                        filter: selectedCategoryFilter,
                        searchText: searchText
                    ) {
                        if !searchText.isEmpty {
                            searchText = ""
                        } else {
                            selectedCategoryFilter = "Todas"
                        }
                    }
                } else {
                    TasksListSection(
                        tasks: filteredTasks,
                        onEdit: { task in showingEditTask = task },
                        onDelete: deleteTask
                    )
                }
                
                Spacer(minLength: 0)
            }
            .navigationTitle("Tareas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                if !model.tasks.isEmpty {
                    FloatingActionButton {
                        showingAdd = true
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTaskView()
                    .environmentObject(model)
            }
            .sheet(item: $showingEditTask) { task in
                EditTaskView(task: task)
                    .environmentObject(model)
            }
            .alert("Eliminar Tarea", isPresented: $showingDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    if let task = taskToDelete {
                        model.deleteTask(taskId: task.id)
                        taskToDelete = nil
                    }
                }
                Button("Cancelar", role: .cancel) {
                    taskToDelete = nil
                }
            } message: {
                Text("¿Estás seguro de que quieres eliminar esta tarea? Esta acción no se puede deshacer.")
            }
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        taskToDelete = filteredTasks[index]
        showingDeleteAlert = true
    }
}

// MARK: - Tasks Header Section
struct TasksHeaderSection: View {
    let totalTasks: Int
    let filteredCount: Int
    let selectedFilter: String
    let categoryCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                HeaderStatCard(
                    title: "Total",
                    value: "\(totalTasks)",
                    subtitle: "tareas",
                    color: .blue,
                    icon: "list.bullet.rectangle"
                )
                
                HeaderStatCard(
                    title: selectedFilter == "Todas" ? "Activas" : "Filtradas",
                    value: "\(filteredCount)",
                    subtitle: selectedFilter == "Todas" ? "visibles" : "coinciden",
                    color: .green,
                    icon: selectedFilter == "Todas" ? "eye" : "line.3.horizontal.decrease.circle"
                )
                
                HeaderStatCard(
                    title: "Categorías",
                    value: "\(categoryCount)",
                    subtitle: "creadas",
                    color: .purple,
                    icon: "tag.fill"
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Header Stat Card
struct HeaderStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(color)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Search Bar Section
struct SearchBarSection: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Buscar tareas...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Category Filter Section
struct CategoryFilterSection: View {
    @Binding var selectedFilter: String
    let categories: [TaskCategory]
    let taskCounts: [String: Int]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All tasks filter
                CategoryFilterChip(
                    title: "Todas",
                    icon: "list.bullet",
                    count: taskCounts["Todas"] ?? 0,
                    isSelected: selectedFilter == "Todas",
                    color: .blue
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = "Todas"
                    }
                }
                
                // Uncategorized filter
                if let uncategorizedCount = taskCounts["Sin categoría"], uncategorizedCount > 0 {
                    CategoryFilterChip(
                        title: "Sin categoría",
                        icon: "circle",
                        count: uncategorizedCount,
                        isSelected: selectedFilter == "Sin categoría",
                        color: .gray
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFilter = "Sin categoría"
                        }
                    }
                }
                
                // Category filters
                ForEach(categories) { category in
                    if let count = taskCounts[category.name], count > 0 {
                        CategoryFilterChip(
                            title: category.name,
                            icon: category.icon,
                            count: count,
                            isSelected: selectedFilter == category.name,
                            color: category.swiftUIColor
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFilter = category.name
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.white.opacity(0.9) : color.opacity(0.2),
                        in: Capsule()
                    )
                    .foregroundStyle(isSelected ? color : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tasks List Section
struct TasksListSection: View {
    let tasks: [TaskItem]
    let onEdit: (TaskItem) -> Void
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                ModernTaskRow(task: task) {
                    onEdit(task)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: onDelete)
            
            // Extra space for floating button
            Color.clear
                .frame(height: 100)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Modern Task Row
struct ModernTaskRow: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    let onEdit: () -> Void
    
    private var category: TaskCategory? {
        model.getCategoryForTask(task)
    }
    
    private var isCompletedToday: Bool {
        model.isTaskCompletedToday(task.id)
    }
    
    private var isActiveToday: Bool {
        model.isTaskActiveToday(task.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(category?.swiftUIColor ?? .gray)
                .frame(width: 4, height: 50)
            
            // Task content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Today completion status
                    if isCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
                
                HStack(spacing: 8) {
                    if let category = category {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(category.swiftUIColor)
                        
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if isActiveToday {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            
                            Text("Activa hoy")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1), in: Capsule())
                    }
                    
                    Spacer()
                }
            }
            
            // Toggle para activar/desactivar la tarea para hoy
            Toggle("Activa para hoy", isOn: Binding(
                get: { isActiveToday },
                set: { newValue in
                    if newValue {
                        // Activar tarea para hoy
                        if !model.isTaskActiveToday(task.id) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let key = formatter.string(from: Date())
                            
                            // Crear o encontrar el record de hoy
                            if let recordIndex = model.records.firstIndex(where: { $0.date == key }) {
                                // El record existe, agregar la tarea
                                model.records[recordIndex].statuses.append(TaskStatus(taskId: task.id, completed: false))
                            } else {
                                // Crear nuevo record para hoy
                                let newRecord = DailyRecord(
                                    date: key,
                                    statuses: [TaskStatus(taskId: task.id, completed: false)]
                                )
                                model.records.append(newRecord)
                            }
                            model.saveRecords()
                        }
                    } else {
                        // Desactivar tarea para hoy
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let key = formatter.string(from: Date())
                        
                        if let recordIndex = model.records.firstIndex(where: { $0.date == key }) {
                            model.records[recordIndex].statuses.removeAll { $0.taskId == task.id }
                            model.saveRecords()
                        }
                    }
                }
            ))
            .labelsHidden()
            .tint(.blue)
            .scaleEffect(1.1)
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCompletedToday ? 
                        .green.opacity(0.3) : 
                        isActiveToday ? .blue.opacity(0.3) : .clear,
                    lineWidth: 2
                )
        )
        .padding(.vertical, 2)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty States
struct EmptyAllTasksView: View {
    let onAddTask: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("¡Comienza a organizarte!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Crea tu primera tarea y empieza a ser más productivo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button(action: onAddTask) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Crear Primera Tarea")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyFilteredTasksView: View {
    let filter: String
    let searchText: String
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: searchText.isEmpty ? "line.3.horizontal.decrease.circle" : "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 4) {
                    Text(searchText.isEmpty ? "Sin tareas en esta categoría" : "Sin resultados")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(searchText.isEmpty ?
                         "No hay tareas en '\(filter)'" :
                         "No se encontraron tareas con '\(searchText)'"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onReset) {
                Text(searchText.isEmpty ? "Ver todas las tareas" : "Limpiar búsqueda")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @EnvironmentObject var model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    
    let task: TaskItem
    @State private var title: String
    @State private var selectedCategoryId: UUID?
    
    init(task: TaskItem) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._selectedCategoryId = State(initialValue: task.categoryId)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles de la Tarea") {
                    TextField("Título", text: $title)
                }
                
                if !model.categories.isEmpty {
                    Section("Categoría") {
                        Picker("Categoría", selection: $selectedCategoryId) {
                            Text("Sin categoría")
                                .tag(nil as UUID?)
                            
                            ForEach(model.categories) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(category.swiftUIColor)
                                    Text(category.name)
                                }
                                .tag(category.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Editar Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update task properties directly
        var updatedTask = task
        updatedTask.title = trimmedTitle
        updatedTask.categoryId = selectedCategoryId
        
        // Find and update the task in the model
        if let index = model.tasks.firstIndex(where: { $0.id == task.id }) {
            model.tasks[index] = updatedTask
            model.saveTasks()
        }
        
        dismiss()
    }
}

#Preview {
    TasksView()
        .environmentObject(ChoreModel())
}
