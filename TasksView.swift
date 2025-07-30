import SwiftUI

struct TasksView: View {
    @EnvironmentObject var model: ChoreModel
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
    
    private var sortedCategories: [TaskCategory] {
        let priorityCategories = ["Casa", "Trabajo", "Personal", "Salud"]
        let priorityItems = model.categories.filter { priorityCategories.contains($0.name) }
        let otherItems = model.categories.filter { !priorityCategories.contains($0.name) }
        return priorityItems + otherItems
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Category Filter Section with enhanced design
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "Todas" filter
                        FilterChip(
                            title: "Todas",
                            icon: "list.bullet",
                            isSelected: selectedCategoryFilter == "Todas",
                            color: .blue
                        ) {
                            selectedCategoryFilter = "Todas"
                        }
                        
                        // "Sin categoría" filter
                        FilterChip(
                            title: "Sin categoría",
                            icon: "circle",
                            isSelected: selectedCategoryFilter == "Sin categoría",
                            color: .gray
                        ) {
                            selectedCategoryFilter = "Sin categoría"
                        }
                        
                        // Category filters
                        ForEach(sortedCategories) { category in
                            FilterChip(
                                title: category.name,
                                icon: category.icon,
                                isSelected: selectedCategoryFilter == category.name,
                                color: category.swiftUIColor
                            ) {
                                selectedCategoryFilter = category.name
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Task List with improved spacing
                List {
                    if filteredTasks.isEmpty {
                        // Enhanced empty state view
                        EmptyTasksView(selectedFilter: selectedCategoryFilter) {
                            showingAdd = true
                        }
                        .frame(height: 400)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredTasks) { task in
                            EnhancedTaskRow(task: task)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteTask)
                        
                        // Extra spacing at bottom for floating button
                        Color.clear
                            .frame(height: 80)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground))
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        showingAdd = true
                    } label: {
                        ZStack {
                            // Shadow layer
                            Circle()
                                .fill(.blue)
                                .frame(width: 60, height: 60)
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
                            
                            // Main button
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            // Plus icon
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(FloatingButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Tareas")
        .navigationBarTitleDisplayMode(.large)
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
            Button("Eliminar", role: .destructive) {
                model.deleteTask(taskId: task.id)
                taskToDelete = nil
            }
        } message: { task in
            Text("¿Estás seguro de que quieres eliminar '\(task.title)'? Esta acción no se puede deshacer.")
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            taskToDelete = filteredTasks[index]
            showingDeleteAlert = true
        }
    }
}

// MARK: - Floating Button Style
struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Filter Chip Component
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? color : Color(.systemGray5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.25) : .black.opacity(0.05),
                        radius: isSelected ? 6 : 2,
                        x: 0,
                        y: isSelected ? 3 : 1
                    )
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Enhanced Task Row Component
struct EnhancedTaskRow: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    @State private var isPressed = false
    
    private var category: TaskCategory? {
        model.getCategoryForTask(task)
    }
    
    private var isActiveToday: Bool {
        model.isTaskActiveToday(task.id)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced category icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (category?.swiftUIColor ?? Color.gray).opacity(0.15),
                                (category?.swiftUIColor ?? Color.gray).opacity(0.05)
                            ],
                            center: .topLeading,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke((category?.swiftUIColor ?? Color.gray).opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: category?.icon ?? "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(category?.swiftUIColor ?? .gray)
            }
            
            // Task content with enhanced typography
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 10) {
                    if let category = category {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.swiftUIColor)
                                .frame(width: 6, height: 6)
                            
                            Text(category.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(category.swiftUIColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(category.swiftUIColor.opacity(0.1))
                        )
                    }
                    
                    if isActiveToday {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            
                            Text("Activa hoy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.green.opacity(0.1))
                        )
                    }
                }
            }
            
            Spacer()
            
            // Enhanced toggle with custom design
            Toggle("Tarea", isOn: Binding(
                get: { isActiveToday },
                set: { newValue in
                    if newValue {
                        if !model.isTaskActiveToday(task.id) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let key = formatter.string(from: Date())
                            if let recordIndex = model.records.firstIndex(where: { $0.date == key }) {
                                model.records[recordIndex].statuses.append(TaskStatus(taskId: task.id, completed: false))
                                model.saveRecords()
                            }
                        }
                    } else {
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
            .scaleEffect(1.15)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActiveToday)
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Enhanced Empty Tasks View Component
struct EmptyTasksView: View {
    let selectedFilter: String
    @State private var isAnimating = false
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 36) {
            // Animated illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isAnimating)
                
                // Main icon container
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                Image(systemName: selectedFilter == "Todas" ? "tray" : "magnifyingglass")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Enhanced text content
            VStack(spacing: 16) {
                Text(selectedFilter == "Todas" ? "No hay tareas creadas" : "Sin tareas en '\(selectedFilter)'")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(selectedFilter == "Todas"
                     ? "Comienza organizando tu día creando tu primera tarea"
                     : "No tienes tareas en esta categoría. Prueba cambiando el filtro o crea una nueva tarea.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 8)
            }
            
            // Enhanced Create Button (only for "Todas")
            if selectedFilter == "Todas" {
                Button {
                    onCreate()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Crear mi primera tarea")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.35), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(isAnimating ? 1.02 : 1.0)
            }
            
            // Enhanced tip section
            if selectedFilter == "Todas" {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(.yellow.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text("Consejo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    
                    Text("Organiza tus actividades por categorías para tener un mejor control de tu productividad diaria")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.quaternary.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.tertiary, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(40)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}
