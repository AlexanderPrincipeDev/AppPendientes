import SwiftUI

struct TasksView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedDate: Date? = nil
    @State private var showingDayView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar View para seleccionar fechas
                TaskCalendarView(selectedDate: $selectedDate, showingDayView: $showingDayView)
                
                // Sección de resumen rápido
                TasksSummarySection()
                    .padding()
            }
            .navigationTitle("Tareas")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDayView) {
                selectedDate = nil
            } content: {
                if let selectedDate = selectedDate {
                    DayTasksView(date: selectedDate)
                        .environmentObject(model)
                        .environmentObject(notificationService)
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                if newValue != nil && !showingDayView {
                    showingDayView = true
                }
            }
        }
    }
}

// MARK: - Task Calendar View
struct TaskCalendarView: View {
    @EnvironmentObject var model: ChoreModel
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstDayOfMonth = monthInterval.start
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = (firstDayWeekday - 1) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks × 7 days
            if let day = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(day)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header con título
            HStack {
                Text("Selecciona una fecha para crear tareas")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(daysInMonth, id: \.self) { date in
                    TaskCalendarDayView(
                        date: date,
                        currentMonth: currentMonth,
                        selectedDate: $selectedDate,
                        showingDayView: $showingDayView
                    )
                    .environmentObject(model)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Task Calendar Day View
struct TaskCalendarDayView: View {
    @EnvironmentObject var model: ChoreModel
    let date: Date
    let currentMonth: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    
    private let calendar = Calendar.current
    
    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var tasksForDate: [TaskItem] {
        model.tasks.filter { task in
            if task.taskType == .specific, let specificDate = task.specificDate {
                return calendar.isDate(specificDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    private var hasTasksForDate: Bool {
        !tasksForDate.isEmpty
    }
    
    private var textColor: Color {
        if !isInCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if hasTasksForDate {
            return .green.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    var body: some View {
        Button(action: dayTapped) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundStyle(textColor)
                
                // Indicador de tareas
                if hasTasksForDate {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? .clear : .clear, lineWidth: 1)
            )
        }
        .disabled(!isInCurrentMonth)
        .buttonStyle(.plain)
    }
    
    private func dayTapped() {
        guard isInCurrentMonth else { return }
        selectedDate = date
    }
}

// MARK: - Tasks Summary Section
struct TasksSummarySection: View {
    @EnvironmentObject var model: ChoreModel
    
    private var totalTasks: Int {
        model.tasks.count
    }
    
    private var activeTasks: Int {
        model.tasks.filter { $0.taskType == .daily }.count
    }
    
    private var totalCategories: Int {
        model.categories.count
    }
    
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
                    title: "Diarias",
                    value: "\(activeTasks)",
                    subtitle: "activas",
                    color: .green,
                    icon: "repeat"
                )
                
                HeaderStatCard(
                    title: "Categorías",
                    value: "\(totalCategories)",
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

// MARK: - Add Task For Date View
struct AddTaskForDateView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskCategory?
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    @State private var repeatDaily = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var canSave: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Crear tarea para: \(formattedDate)")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.vertical, 4)
                } header: {
                    Text("Fecha seleccionada")
                }
                
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
                    Button("Crear") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isTextFieldFocused = true
            // Configurar la hora del recordatorio para la fecha seleccionada
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            if let newReminderTime = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                   minute: timeComponents.minute ?? 0,
                                                   second: 0,
                                                   of: date) {
                reminderTime = newReminderTime
            }
        }
    }
    
    private func saveTask() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        // Crear la tarea específica para la fecha seleccionada
        let task = TaskItem(
            title: title,
            categoryId: selectedCategory?.id,
            hasReminder: hasReminder,
            reminderTime: hasReminder ? reminderTime : nil,
            repeatDaily: repeatDaily,
            specificDate: date,
            taskType: .specific
        )
        
        model.tasks.append(task)
        model.saveTasks()
        
        // Programar notificación si está habilitada
        if hasReminder {
            notificationService.scheduleTaskReminder(for: task, at: reminderTime, repeatDaily: repeatDaily)
        }
        
        dismiss()
    }
}

// MARK: - Day Tasks View
struct DayTasksView: View {
    @EnvironmentObject var model: ChoreModel
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss
    
    let date: Date
    @State private var showingAddTaskForm = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("\(tasksForDate.count) tarea\(tasksForDate.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Cerrar") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                    
                    Divider()
                }
                .padding()
                .background(.regularMaterial)
                
                // Lista de tareas o estado vacío
                if tasksForDate.isEmpty {
                    // Estado vacío
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No hay tareas para este día")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Toca el botón + para crear tu primera tarea")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Crear Primera Tarea") {
                            showingAddTaskForm = true
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
                } else {
                    // Lista de tareas
                    List {
                        ForEach(tasksForDate) { task in
                            TaskRowView(task: task)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    toggleTaskCompletion(task)
                                }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(.thinMaterial)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Botón flotante para agregar tarea (solo si hay tareas)
                if !tasksForDate.isEmpty {
                    Button(action: {
                        showingAddTaskForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(.blue, in: Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .presentationDetents([.height(600), .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingAddTaskForm) {
            AddTaskForDateView(date: date)
                .environmentObject(model)
                .environmentObject(notificationService)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private var tasksForDate: [TaskItem] {
        model.tasks.filter { task in
            if task.taskType == .specific, let specificDate = task.specificDate {
                return Calendar.current.isDate(specificDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        model.toggle(taskId: task.id)
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = tasksForDate[index]
            if let taskIndex = model.tasks.firstIndex(where: { $0.id == task.id }) {
                model.tasks.remove(at: taskIndex)
            }
        }
        model.saveTasks()
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    
    private var isCompleted: Bool {
        let todayRecord = model.todayRecord
        return todayRecord.statuses.first(where: { $0.taskId == task.id })?.completed ?? false
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Estado de la tarea
            Button(action: {
                model.toggle(taskId: task.id)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                
                HStack(spacing: 8) {
                    // Categoría
                    if let category = model.categories.first(where: { $0.id == task.categoryId }) {
                        Label {
                            Text(category.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.swiftUIColor)
                                .font(.caption)
                        }
                    }
                    
                    // Recordatorio
                    if task.hasReminder, let reminderTime = task.reminderTime {
                        Label {
                            Text(reminderTimeFormatter.string(from: reminderTime))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.blue)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var reminderTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    NavigationStack {
        TasksView()
            .environmentObject(ChoreModel())
            .environmentObject(NotificationService.shared)
    }
}
