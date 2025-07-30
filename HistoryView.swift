import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var selectedDate: Date? = nil
    @State private var showingDayDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar View
                CalendarView(selectedDate: $selectedDate, showingDayDetail: $showingDayDetail)
                
                // Quick Stats Section - Siempre mostrar
                QuickStatsSection()
                    .padding()
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDayDetail) {
                // Limpiar selectedDate cuando se cierre el sheet
                selectedDate = nil
            } content: {
                if let selectedDate = selectedDate {
                    DayDetailView(date: selectedDate)
                        .environmentObject(model)
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                // Solo mostrar el sheet cuando selectedDate esté completamente establecido
                if newValue != nil && !showingDayDetail {
                    showingDayDetail = true
                }
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var model: ChoreModel
    @Binding var selectedDate: Date?
    @Binding var showingDayDetail: Bool
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
                    CalendarDayView(
                        date: date,
                        currentMonth: currentMonth,
                        selectedDate: $selectedDate,
                        showingDayDetail: $showingDayDetail
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

// MARK: - Calendar Day View
struct CalendarDayView: View {
    @EnvironmentObject var model: ChoreModel
    let date: Date
    let currentMonth: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayDetail: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    private var dayRecord: DailyRecord? {
        let dateString = dateFormatter.string(from: date)
        return model.records.first { $0.date == dateString }
    }
    
    private var completionRate: Double {
        dayRecord?.completionRate ?? 0
    }
    
    private var hasData: Bool {
        dayRecord != nil && dayRecord!.totalCount > 0
    }
    
    var body: some View {
        Button(action: dayTapped) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundStyle(textColor)
                
                // Progress indicator
                if hasData && !isFuture {
                    Circle()
                        .fill(progressColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 50)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .disabled(isFuture || !hasData)
    }
    
    private var textColor: Color {
        if isFuture || !isInCurrentMonth {
            return .secondary
        } else if isToday {
            return .primary
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue.opacity(0.1)
        } else if hasData && !isFuture {
            return progressColor.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        isToday ? .blue : .clear
    }
    
    private var progressColor: Color {
        if completionRate >= 1.0 {
            return .green
        } else if completionRate >= 0.7 {
            return .orange
        } else if completionRate > 0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func dayTapped() {
        if hasData && !isFuture {
            selectedDate = date
            // Pequeño delay para asegurar que selectedDate se actualice antes de mostrar el sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                showingDayDetail = true
            }
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    @EnvironmentObject var model: ChoreModel
    
    private var last7DaysStats: (totalDays: Int, perfectDays: Int, averageCompletion: Double) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var totalDays = 0
        var perfectDays = 0
        var totalCompletion = 0.0
        
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                totalDays += 1
                totalCompletion += record.completionRate
                if record.completionRate == 1.0 {
                    perfectDays += 1
                }
            }
        }
        
        let average = totalDays > 0 ? totalCompletion / Double(totalDays) : 0
        return (totalDays, perfectDays, average)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumen de la Semana")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Días Activos",
                    value: "\(last7DaysStats.totalDays)",
                    subtitle: "de 7 días",
                    color: .blue
                )
                
                StatCard(
                    title: "Días Perfectos",
                    value: "\(last7DaysStats.perfectDays)",
                    subtitle: "100% completo",
                    color: .green
                )
                
                StatCard(
                    title: "Promedio",
                    value: "\(Int(last7DaysStats.averageCompletion * 100))%",
                    subtitle: "completado",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    @EnvironmentObject var model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    let date: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var dayRecord: DailyRecord? {
        let dateString = dateFormatter.string(from: date)
        return model.records.first { $0.date == dateString }
    }
    
    private var tasksWithStatus: [(task: TaskItem, status: TaskStatus?)] {
        guard let record = dayRecord else { return [] }
        
        return model.tasks.compactMap { task in
            // Only include tasks that existed on this day (have a status in the record)
            if let status = record.statuses.first(where: { $0.taskId == task.id }) {
                return (task: task, status: status)
            }
            return nil
        }
    }
    
    private var completedTasks: [(task: TaskItem, status: TaskStatus)] {
        tasksWithStatus.compactMap { item in
            if let status = item.status, status.completed {
                return (task: item.task, status: status)
            }
            return nil
        }.sorted { first, second in
            (first.status.completedAt ?? Date.distantPast) < (second.status.completedAt ?? Date.distantPast)
        }
    }
    
    private var incompleteTasks: [TaskItem] {
        tasksWithStatus.compactMap { item in
            if let status = item.status, !status.completed {
                return item.task
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date and Summary Header
                    DateSummaryHeader()
                    
                    // Completed Tasks Section
                    if !completedTasks.isEmpty {
                        CompletedTasksSection()
                    }
                    
                    // Incomplete Tasks Section
                    if !incompleteTasks.isEmpty {
                        IncompleteTasksSection()
                    }
                    
                    // Empty State
                    if tasksWithStatus.isEmpty {
                        EmptyDayState()
                    }
                }
                .padding()
            }
            .navigationTitle("Detalle del Día")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(
                        item: generateShareText(),
                        subject: Text("Mi progreso del día"),
                        message: Text("¡Mira mi progreso de tareas!")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Share Functionality
    private func generateShareText() -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_ES")
        dayFormatter.dateFormat = "EEEE, d 'de' MMMM 'de' yyyy"
        let dayString = dayFormatter.string(from: date).capitalized
        
        var shareText = "📅 *\(dayString)*\n\n"
        
        if let record = dayRecord {
            let percentage = Int(record.completionRate * 100)
            shareText += "📊 *Resumen del día*\n"
            shareText += "✅ Completadas: \(record.completedCount)\n"
            shareText += "⏳ Pendientes: \(record.totalCount - record.completedCount)\n"
            shareText += "📈 Progreso: \(percentage)%\n\n"
            
            // Tareas completadas
            if !completedTasks.isEmpty {
                shareText += "✅ *Tareas Completadas:*\n"
                for (index, item) in completedTasks.enumerated() {
                    let timeString = item.status.completedAt?.formatted(.dateTime.hour().minute()) ?? "N/A"
                    let categoryName = model.getCategoryForTask(item.task)?.name ?? ""
                    let categoryEmoji = getCategoryEmoji(for: model.getCategoryForTask(item.task))
                    
                    shareText += "\(index + 1). \(categoryEmoji) \(item.task.title)"
                    if !categoryName.isEmpty {
                        shareText += " (\(categoryName))"
                    }
                    shareText += " - \(timeString)\n"
                }
                shareText += "\n"
            }
            
            // Tareas pendientes
            if !incompleteTasks.isEmpty {
                shareText += "⏳ *Tareas Pendientes:*\n"
                for (index, task) in incompleteTasks.enumerated() {
                    let categoryName = model.getCategoryForTask(task)?.name ?? ""
                    let categoryEmoji = getCategoryEmoji(for: model.getCategoryForTask(task))
                    
                    shareText += "\(index + 1). \(categoryEmoji) \(task.title)"
                    if !categoryName.isEmpty {
                        shareText += " (\(categoryName))"
                    }
                    shareText += "\n"
                }
                shareText += "\n"
            }
            
            // Mensaje motivacional
            if record.completionRate == 1.0 {
                shareText += "🎉 ¡Día perfecto! Completé todas mis tareas 💪"
            } else if record.completionRate >= 0.8 {
                shareText += "🌟 ¡Excelente día! Logré completar la mayoría de mis tareas"
            } else if record.completionRate >= 0.5 {
                shareText += "👍 Buen progreso, completé más de la mitad de mis tareas"
            } else if record.completionRate > 0 {
                shareText += "💪 Día de trabajo, algunas tareas completadas"
            } else {
                shareText += "📝 Día de planificación, preparándome para mañana"
            }
        } else {
            shareText += "📝 No había tareas programadas para este día"
        }
        
        shareText += "\n\n#ProductividadPersonal #OrganizacionDiaria #MetasCumplidas"
        
        return shareText
    }
    
    private func getCategoryEmoji(for category: TaskCategory?) -> String {
        guard let category = category else { return "📝" }
        
        switch category.name.lowercased() {
        case "casa": return "🏠"
        case "trabajo": return "💼"
        case "personal": return "👤"
        case "salud": return "❤️"
        case "ejercicio": return "🏃‍♂️"
        case "estudio": return "📚"
        case "compras": return "🛒"
        case "general": return "⭐"
        default: return "📝"
        }
    }
    
    // MARK: - Date Summary Header
    @ViewBuilder
    private func DateSummaryHeader() -> some View {
        VStack(spacing: 12) {
            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.title2)
                .fontWeight(.semibold)
            
            if let record = dayRecord {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(record.completedCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("Completadas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(record.totalCount - record.completedCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                        Text("Pendientes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int(record.completionRate * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("Progreso")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Completed Tasks Section
    @ViewBuilder
    private func CompletedTasksSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Tareas Completadas")
                    .font(.headline)
                Spacer()
                Text("\(completedTasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(completedTasks, id: \.task.id) { item in
                TaskRow(
                    task: item.task,
                    isCompleted: true,
                    completedAt: item.status.completedAt
                )
            }
        }
        .padding()
        .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Incomplete Tasks Section
    @ViewBuilder
    private func IncompleteTasksSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle")
                    .foregroundStyle(.red)
                Text("Tareas Pendientes")
                    .font(.headline)
                Spacer()
                Text("\(incompleteTasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(incompleteTasks, id: \.id) { task in
                TaskRow(task: task, isCompleted: false)
            }
        }
        .padding()
        .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Empty Day State
    @ViewBuilder
    private func EmptyDayState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Sin actividad")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("No había tareas programadas para este día")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Task Row
struct TaskRow: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    let isCompleted: Bool
    let completedAt: Date?
    
    init(task: TaskItem, isCompleted: Bool, completedAt: Date? = nil) {
        self.task = task
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    private var category: TaskCategory? {
        model.getCategoryForTask(task)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    // Category badge
                    if let category = category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.name)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(category.swiftUIColor.opacity(0.2), in: Capsule())
                        .foregroundStyle(category.swiftUIColor)
                    }
                    
                    // Completion time
                    if let completedAt = completedAt {
                        Text("Completada a las \(completedAt.formatted(.dateTime.hour().minute()))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HistoryView()
        .environmentObject(ChoreModel())
}
