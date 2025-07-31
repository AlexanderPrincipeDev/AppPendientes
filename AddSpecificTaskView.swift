import SwiftUI

struct AddSpecificTaskView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss
    
    let selectedDate: Date
    
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskCategory?
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    @State private var showingCategoryPicker = false
    
    private var isValid: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre de la tarea", text: $taskTitle)
                        .textFieldStyle(.plain)
                } header: {
                    Text("Información básica")
                } footer: {
                    Text("Escribe el nombre de la tarea que quieres realizar el \(formattedDate)")
                }
                
                Section {
                    HStack {
                        Text("Categoría")
                        Spacer()
                        Button(action: { showingCategoryPicker = true }) {
                            Text(selectedCategory?.name ?? "Sin categoría")
                                .foregroundColor(selectedCategory != nil ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let category = selectedCategory {
                        HStack {
                            Circle()
                                .fill(Color(category.color))
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Cambiar") {
                                showingCategoryPicker = true
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Categoría")
                } footer: {
                    Text("Organiza tu tarea asignándole una categoría")
                }
                
                Section {
                    Toggle("Recordatorio", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker("Hora", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Recordatorio")
                } footer: {
                    if hasReminder {
                        Text("Se te notificará el \(formattedDate) a las \(reminderTime, formatter: timeFormatter)")
                    } else {
                        Text("Activar para recibir una notificación")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Fecha programada")
                                .fontWeight(.medium)
                        }
                        
                        Text(formattedDate)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Programación")
                }
            }
            .navigationTitle("Nueva Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveTask()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
                    .environmentObject(model)
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func saveTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Crear la fecha y hora del recordatorio si está activado
        var finalReminderTime: Date? = nil
        if hasReminder {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            finalReminderTime = calendar.date(from: combinedComponents)
        }
        
        let newTask = TaskItem(
            title: trimmedTitle,
            categoryId: selectedCategory?.id,
            hasReminder: hasReminder,
            reminderTime: finalReminderTime,
            repeatDaily: false,
            specificDate: selectedDate,
            taskType: .specific
        )
        
        model.tasks.append(newTask)
        model.saveTasks()
        
        // Programar notificación si está habilitada
        if hasReminder, let finalTime = finalReminderTime {
            notificationService.scheduleTaskReminder(for: newTask, at: finalTime, repeatDaily: false)
        }
        
        dismiss()
    }
}

// MARK: - Category Picker View
struct CategoryPickerView: View {
    @EnvironmentObject var model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: TaskCategory?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Text("Sin categoría")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if !model.categories.isEmpty {
                    Section("Categorías") {
                        ForEach(model.categories) { category in
                            Button(action: {
                                selectedCategory = category
                                dismiss()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(category.color))
                                        .frame(width: 20, height: 20)
                                    
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddSpecificTaskView(selectedDate: Date())
        .environmentObject(ChoreModel())
}
