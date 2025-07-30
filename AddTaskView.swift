import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskCategory?
    @State private var activateForToday = true
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    @State private var repeatDaily = true
    @FocusState private var isTextFieldFocused: Bool
    
    private var canSave: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("¿Qué tarea quieres añadir?", text: $taskTitle)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .autocapitalization(.sentences)
                } header: {
                    Text("Información básica")
                }
                
                Section {
                    Picker("Categoría", selection: $selectedCategory) {
                        Text("Sin categoría")
                            .tag(nil as TaskCategory?)
                        
                        ForEach(model.categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.swiftUIColor)
                                Text(category.name)
                            }
                            .tag(category as TaskCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Categoría")
                }
                
                Section {
                    Toggle("Activar para hoy", isOn: $activateForToday)
                    
                    Toggle("Recordatorio", isOn: $hasReminder)
                        .disabled(notificationService.notificationPermissionStatus != .authorized)
                    
                    if hasReminder {
                        DatePicker("Hora del recordatorio", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        
                        Toggle("Repetir diariamente", isOn: $repeatDaily)
                    }
                } header: {
                    Text("Opciones")
                } footer: {
                    if notificationService.notificationPermissionStatus != .authorized {
                        Text("Para configurar recordatorios, permite las notificaciones en Configuración")
                    } else {
                        Text("Si está activado, la tarea aparecerá en tu lista de hoy")
                    }
                }
            }
            .navigationTitle("Nueva Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Añadir") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func saveTask() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        model.addTask(
            title: title,
            categoryId: selectedCategory?.id,
            hasReminder: hasReminder,
            reminderTime: hasReminder ? reminderTime : nil
        )
        
        if activateForToday, let newTask = model.tasks.last {
            model.activateTaskForToday(taskId: newTask.id)
        }
        
        dismiss()
    }
}
