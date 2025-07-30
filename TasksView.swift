import SwiftUI

struct TasksView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var showingAddTask = false
    @State private var showingAddCategory = false
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
        VStack(spacing: 0) {
            // Header with add buttons
            VStack(spacing: 12) {
                HStack {
                    Text("Gestionar Tareas")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Add Task Button
                    Button {
                        showingAddTask = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Agregar Tarea")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Add Category Button
                    Button {
                        showingAddCategory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 16))
                            Text("Nueva Categoría")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            
            // Category Filter Section
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "Todas" filter
                    Button {
                        selectedCategoryFilter = "Todas"
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12))
                            Text("Todas")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedCategoryFilter == "Todas" ? .blue : Color(.systemGray6))
                        )
                        .foregroundStyle(selectedCategoryFilter == "Todas" ? .white : .primary)
                    }
                    
                    // "Sin categoría" filter
                    Button {
                        selectedCategoryFilter = "Sin categoría"
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "circle")
                                .font(.system(size: 12))
                            Text("Sin categoría")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedCategoryFilter == "Sin categoría" ? .gray : Color(.systemGray6))
                        )
                        .foregroundStyle(selectedCategoryFilter == "Sin categoría" ? .white : .primary)
                    }
                    
                    // Category filters
                    ForEach(sortedCategories) { category in
                        Button {
                            selectedCategoryFilter = category.name
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.name)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategoryFilter == category.name ? category.swiftUIColor : Color(.systemGray6))
                            )
                            .foregroundStyle(selectedCategoryFilter == category.name ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.3))
            
            // Task List Section
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Tareas")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(filteredTasks.count) tarea\(filteredTasks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                if filteredTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("No hay tareas")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Agrega tu primera tarea usando el botón de arriba")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            HStack {
                                // Category icon
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
                                
                                Spacer()
                                
                                Toggle("Tarea", isOn: Binding(
                                    get: {
                                        model.todayRecord.statuses.contains { $0.taskId == task.id }
                                    },
                                    set: { newValue in
                                        if newValue {
                                            // Add task to today's record if not already there
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
                                            // Remove task from today's record
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
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteTask)
                    }
                }
            }
        }
        .navigationTitle("Tareas")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(model)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
                .environmentObject(model)
                .presentationDetents([.height(300)])
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
