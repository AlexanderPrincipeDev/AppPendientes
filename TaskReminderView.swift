import SwiftUI

struct TaskReminderView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss
    
    let task: TaskItem
    
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    @State private var repeatDaily: Bool
    
    init(task: TaskItem) {
        self.task = task
        self._hasReminder = State(initialValue: task.hasReminder)
        self._reminderTime = State(initialValue: task.reminderTime ?? Date())
        self._repeatDaily = State(initialValue: task.repeatDaily)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text(task.title)
                            .font(.headline)
                    }
                } header: {
                    Text("Tarea")
                }
                
                Section {
                    Toggle("Activar recordatorio", isOn: $hasReminder)
                        .disabled(notificationService.notificationPermissionStatus != .authorized)
                    
                    if hasReminder {
                        DatePicker("Hora", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        
                        Toggle("Repetir diariamente", isOn: $repeatDaily)
                    }
                } header: {
                    Text("Configuración del recordatorio")
                } footer: {
                    if notificationService.notificationPermissionStatus != .authorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Para configurar recordatorios, permite las notificaciones en Configuración del dispositivo.")
                            
                            Button("Abrir Configuración") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    } else if hasReminder {
                        Text("Recibirás una notificación a las \(reminderTime.formatted(date: .omitted, time: .shortened))")
                    }
                }
            }
            .navigationTitle("Recordatorio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
    
    private func saveReminder() {
        model.updateTaskReminder(
            taskId: task.id,
            hasReminder: hasReminder,
            reminderTime: hasReminder ? reminderTime : nil,
            repeatDaily: repeatDaily
        )
        dismiss()
    }
}