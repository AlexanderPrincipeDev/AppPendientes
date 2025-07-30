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
    @State private var showingWeeklyDetail = false
    
    private var last7DaysStats: (totalDays: Int, perfectDays: Int, averageCompletion: Double, totalTasks: Int, streak: Int, bestDay: String, bestDayRate: Double, productivity: String) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var totalDays = 0
        var perfectDays = 0
        var totalCompletion = 0.0
        var totalTasks = 0
        var streak = 0
        var bestDay = ""
        var bestDayRate = 0.0
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_ES")
        dayFormatter.dateFormat = "EEEE"
        
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                totalDays += 1
                totalTasks += record.totalCount
                totalCompletion += record.completionRate
                
                if record.completionRate == 1.0 {
                    perfectDays += 1
                }
                
                if record.completionRate > 0.7 {
                    streak += 1
                }
                
                if record.completionRate > bestDayRate {
                    bestDayRate = record.completionRate
                    bestDay = dayFormatter.string(from: date).capitalized
                }
            }
        }
        
        let average = totalDays > 0 ? totalCompletion / Double(totalDays) : 0
        
        // Determinar nivel de productividad
        let productivity: String
        if average >= 0.9 {
            productivity = "🚀 MÁQUINA"
        } else if average >= 0.8 {
            productivity = "⭐ INCREÍBLE"
        } else if average >= 0.6 {
            productivity = "💪 GENIAL"
        } else if average >= 0.4 {
            productivity = "📈 MEJORANDO"
        } else {
            productivity = "🌱 CRECIENDO"
        }
        
        return (totalDays, perfectDays, average, totalTasks, streak, bestDay, bestDayRate, productivity)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resumen de la Semana")
                        .font(.headline)
                    
                    Text(last7DaysStats.productivity)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    showingWeeklyDetail = true
                }) {
                    HStack(spacing: 4) {
                        Text("Ver Análisis")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.1), in: Capsule())
                }
            }
            
            HStack(spacing: 12) {
                WeeklyStatCard(
                    emoji: "🎯",
                    title: "Tareas",
                    value: "\(last7DaysStats.totalTasks)",
                    subtitle: "esta semana",
                    color: .blue,
                    isMainStat: true
                )
                
                WeeklyStatCard(
                    emoji: last7DaysStats.perfectDays >= 3 ? "🏆" : last7DaysStats.perfectDays >= 1 ? "⭐" : "💪",
                    title: "Días Perfectos",
                    value: "\(last7DaysStats.perfectDays)",
                    subtitle: last7DaysStats.perfectDays >= 3 ? "¡Impresionante!" : last7DaysStats.perfectDays >= 1 ? "¡Genial!" : "¡A por más!",
                    color: last7DaysStats.perfectDays >= 3 ? .green : last7DaysStats.perfectDays >= 1 ? .orange : .red,
                    isMainStat: false
                )
                
                WeeklyStatCard(
                    emoji: last7DaysStats.streak >= 5 ? "🔥" : last7DaysStats.streak >= 3 ? "⚡" : "📈",
                    title: "Racha",
                    value: "\(last7DaysStats.streak)",
                    subtitle: last7DaysStats.streak >= 5 ? "¡Imparable!" : last7DaysStats.streak >= 3 ? "¡En llamas!" : "días activos",
                    color: last7DaysStats.streak >= 5 ? .red : last7DaysStats.streak >= 3 ? .orange : .blue,
                    isMainStat: false
                )
            }
            
            // Barra de progreso semanal más visual
            VStack(spacing: 8) {
                HStack {
                    Text("Progreso Semanal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(last7DaysStats.averageCompletion * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                }
                
                ProgressView(value: last7DaysStats.averageCompletion)
                    .progressViewStyle(CustomProgressViewStyle(color: progressColor))
            }
            
            // Mensaje motivacional dinámico
            if !last7DaysStats.bestDay.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    
                    Text("Tu mejor día fue \(last7DaysStats.bestDay) con \(Int(last7DaysStats.bestDayRate * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingWeeklyDetail) {
            WeeklyDetailView()
                .environmentObject(model)
        }
    }
    
    private var progressColor: Color {
        let average = last7DaysStats.averageCompletion
        if average >= 0.9 {
            return .green
        } else if average >= 0.7 {
            return .blue
        } else if average >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Weekly Stat Card
struct WeeklyStatCard: View {
    let emoji: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let isMainStat: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(isMainStat ? .title2 : .title3)
            
            Text(value)
                .font(isMainStat ? .title2 : .headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(color)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Progress View Style
struct CustomProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 8)
                    .opacity(0.1)
                    .foregroundStyle(color)
                
                Rectangle()
                    .frame(width: min(CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, geometry.size.width), height: 8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .animation(.easeInOut(duration: 0.5), value: configuration.fractionCompleted)
            }
            .cornerRadius(4)
        }
        .frame(height: 8)
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
                    
                    // Go to Today Button (only show if it's today and has incomplete tasks)
                    if isToday && !incompleteTasks.isEmpty {
                        GoToTodayButton()
                    }
                    
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
    
    // MARK: - Helper Properties
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // MARK: - Go to Today Button
    @ViewBuilder
    private func GoToTodayButton() -> some View {
        Button(action: goToToday) {
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ir a Tareas de Hoy")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Tienes \(incompleteTasks.count) tarea\(incompleteTasks.count == 1 ? "" : "s") pendiente\(incompleteTasks.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.orange.opacity(0.1), .yellow.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func goToToday() {
        // Dismiss the current detail view
        dismiss()
        
        // Post a notification to switch to Today tab
        NotificationCenter.default.post(
            name: NSNotification.Name("SwitchToTodayTab"),
            object: nil
        )
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

// MARK: - Weekly Detail View
struct WeeklyDetailView: View {
    @EnvironmentObject var model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    
    private var weeklyAnalytics: WeeklyAnalytics {
        calculateWeeklyAnalytics()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with big numbers
                    WeeklyHeroSection(analytics: weeklyAnalytics)
                    
                    // Performance section
                    PerformanceSection(analytics: weeklyAnalytics)
                    
                    // Fun facts section
                    FunFactsSection(analytics: weeklyAnalytics)
                    
                    // Time analysis section
                    TimeAnalysisSection(analytics: weeklyAnalytics)
                    
                    // Motivation section
                    MotivationSection(analytics: weeklyAnalytics)
                }
                .padding()
            }
            .navigationTitle("📊 Análisis Semanal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func calculateWeeklyAnalytics() -> WeeklyAnalytics {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var totalTasks = 0
        var completedTasks = 0
        var perfectDays = 0
        var activeDays = 0
        var currentStreak = 0
        var longestStreak = 0
        var bestDayName = ""
        var worstDayName = ""
        var bestDayRate = 0.0
        var worstDayRate = 1.0
        var morningTasks = 0
        var afternoonTasks = 0
        var eveningTasks = 0
        var categoryStats: [String: Int] = [:]
        var dailyRates: [Double] = []
        var hourlyDistribution: [Int] = Array(repeating: 0, count: 24)
        
        // Calcular streak actual
        for i in 0...13 { // Mirar hasta 2 semanas atrás para streak
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                if record.completionRate > 0.5 {
                    if i <= 6 { currentStreak += 1 } // Solo contar última semana para streak actual
                    longestStreak += 1
                } else {
                    if longestStreak > 0 { break }
                }
            } else {
                if longestStreak > 0 { break }
            }
        }
        
        // Analizar última semana
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                activeDays += 1
                totalTasks += record.totalCount
                completedTasks += record.completedCount
                dailyRates.append(record.completionRate)
                
                if record.completionRate == 1.0 {
                    perfectDays += 1
                }
                
                // Mejor y peor día
                if record.completionRate > bestDayRate {
                    bestDayRate = record.completionRate
                    let dayFormatter = DateFormatter()
                    dayFormatter.locale = Locale(identifier: "es_ES")
                    dayFormatter.dateFormat = "EEEE"
                    bestDayName = dayFormatter.string(from: date).capitalized
                }
                
                if record.completionRate < worstDayRate && record.completionRate < 1.0 {
                    worstDayRate = record.completionRate
                    let dayFormatter = DateFormatter()
                    dayFormatter.locale = Locale(identifier: "es_ES")
                    dayFormatter.dateFormat = "EEEE"
                    worstDayName = dayFormatter.string(from: date).capitalized
                }
                
                // Analizar tareas completadas del día
                for status in record.statuses where status.completed {
                    if let task = model.tasks.first(where: { $0.id == status.taskId }),
                       let completedAt = status.completedAt {
                        
                        // Análisis por categoría
                        let categoryName = model.getCategoryForTask(task)?.name ?? "Sin categoría"
                        categoryStats[categoryName] = (categoryStats[categoryName] ?? 0) + 1
                        
                        // Análisis por hora
                        let hour = calendar.component(.hour, from: completedAt)
                        hourlyDistribution[hour] += 1
                        
                        // Análisis por período del día
                        if hour >= 5 && hour < 12 {
                            morningTasks += 1
                        } else if hour >= 12 && hour < 18 {
                            afternoonTasks += 1
                        } else {
                            eveningTasks += 1
                        }
                    }
                }
            }
        }
        
        let averageCompletion = dailyRates.isEmpty ? 0 : dailyRates.reduce(0, +) / Double(dailyRates.count)
        let favoriteCategory = categoryStats.max(by: { $0.value < $1.value })?.key ?? "Ninguna"
        let peakHour = hourlyDistribution.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        
        return WeeklyAnalytics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            averageCompletion: averageCompletion,
            perfectDays: perfectDays,
            activeDays: activeDays,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            bestDay: bestDayName,
            worstDay: worstDayName,
            bestDayRate: bestDayRate,
            worstDayRate: worstDayRate,
            favoriteCategory: favoriteCategory,
            morningTasks: morningTasks,
            afternoonTasks: afternoonTasks,
            eveningTasks: eveningTasks,
            peakHour: peakHour,
            categoryStats: categoryStats,
            dailyRates: dailyRates
        )
    }
}

// MARK: - Weekly Analytics Data Model
struct WeeklyAnalytics {
    let totalTasks: Int
    let completedTasks: Int
    let averageCompletion: Double
    let perfectDays: Int
    let activeDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let bestDay: String
    let worstDay: String
    let bestDayRate: Double
    let worstDayRate: Double
    let favoriteCategory: String
    let morningTasks: Int
    let afternoonTasks: Int
    let eveningTasks: Int
    let peakHour: Int
    let categoryStats: [String: Int]
    let dailyRates: [Double]
}

// MARK: - Weekly Hero Section
struct WeeklyHeroSection: View {
    let analytics: WeeklyAnalytics
    
    var body: some View {
        VStack(spacing: 20) {
            // Main achievement
            VStack(spacing: 8) {
                Text(heroTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(heroSubtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Big numbers grid
            HStack(spacing: 16) {
                BigStatCard(
                    number: "\(analytics.completedTasks)",
                    label: "Tareas\nCompletadas",
                    emoji: "✅",
                    color: .green
                )
                
                BigStatCard(
                    number: "\(Int(analytics.averageCompletion * 100))%",
                    label: "Promedio\nSemanal",
                    emoji: "📈",
                    color: .blue
                )
                
                BigStatCard(
                    number: "\(analytics.currentStreak)",
                    label: "Racha\nActual",
                    emoji: "🔥",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
    
    private var heroTitle: String {
        if analytics.averageCompletion >= 0.9 {
            return "🚀 ¡MÁQUINA DE PRODUCTIVIDAD!"
        } else if analytics.averageCompletion >= 0.8 {
            return "⭐ ¡SEMANA ESPECTACULAR!"
        } else if analytics.averageCompletion >= 0.6 {
            return "👍 ¡BUEN TRABAJO!"
        } else if analytics.averageCompletion >= 0.4 {
            return "📈 ¡VAMOS MEJORANDO!"
        } else {
            return "💪 ¡A POR TODAS!"
        }
    }
    
    private var heroSubtitle: String {
        if analytics.perfectDays >= 3 {
            return "Dominas el arte de la productividad"
        } else if analytics.perfectDays >= 1 {
            return "Tienes días increíbles"
        } else if analytics.averageCompletion >= 0.5 {
            return "Vas por buen camino"
        } else {
            return "Cada día es una nueva oportunidad"
        }
    }
}

// MARK: - Big Stat Card
struct BigStatCard: View {
    let number: String
    let label: String
    let emoji: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 32))
            
            Text(number)
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Performance Section
struct PerformanceSection: View {
    let analytics: WeeklyAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏆 Rendimiento")
                .font(.headline)
            
            VStack(spacing: 12) {
                if !analytics.bestDay.isEmpty {
                    PerformanceRow(
                        icon: "crown.fill",
                        title: "Mejor día",
                        value: analytics.bestDay,
                        subtitle: "\(Int(analytics.bestDayRate * 100))% completado",
                        color: .yellow
                    )
                }
                
                if !analytics.worstDay.isEmpty && analytics.worstDay != analytics.bestDay {
                    PerformanceRow(
                        icon: "arrow.up.circle.fill",
                        title: "Día de mejora",
                        value: analytics.worstDay,
                        subtitle: "Oportunidad de crecimiento",
                        color: .orange
                    )
                }
                
                PerformanceRow(
                    icon: "star.fill",
                    title: "Categoría favorita",
                    value: analytics.favoriteCategory,
                    subtitle: "\(analytics.categoryStats[analytics.favoriteCategory] ?? 0) tareas completadas",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Performance Row
struct PerformanceRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Fun Facts Section
struct FunFactsSection: View {
    let analytics: WeeklyAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎉 Datos Curiosos")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FunFactCard(
                    emoji: "⏰",
                    fact: "Hora pico",
                    value: formatPeakHour(),
                    description: "Tu momento más productivo"
                )
                
                FunFactCard(
                    emoji: preferredTimeEmoji,
                    fact: "Prefieres",
                    value: preferredTime,
                    description: "\(preferredTimeCount) tareas"
                )
                
                if analytics.currentStreak >= 3 {
                    FunFactCard(
                        emoji: "🔥",
                        fact: "¡En racha!",
                        value: "\(analytics.currentStreak) días",
                        description: "¡Sigue así!"
                    )
                }
                
                if analytics.totalTasks > 0 {
                    FunFactCard(
                        emoji: "🎯",
                        fact: "Eficiencia",
                        value: "\(Int(Double(analytics.completedTasks) / Double(analytics.totalTasks) * 100))%",
                        description: "Tareas logradas"
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatPeakHour() -> String {
        if analytics.peakHour == 0 { return "12:00 AM" }
        if analytics.peakHour < 12 { return "\(analytics.peakHour):00 AM" }
        if analytics.peakHour == 12 { return "12:00 PM" }
        return "\(analytics.peakHour - 12):00 PM"
    }
    
    private var preferredTime: String {
        let morning = analytics.morningTasks
        let afternoon = analytics.afternoonTasks
        let evening = analytics.eveningTasks
        
        if morning >= afternoon && morning >= evening {
            return "Mañanas"
        } else if afternoon >= evening {
            return "Tardes"
        } else {
            return "Noches"
        }
    }
    
    private var preferredTimeEmoji: String {
        let morning = analytics.morningTasks
        let afternoon = analytics.afternoonTasks
        let evening = analytics.eveningTasks
        
        if morning >= afternoon && morning >= evening {
            return "🌅"
        } else if afternoon >= evening {
            return "☀️"
        } else {
            return "🌙"
        }
    }
    
    private var preferredTimeCount: Int {
        max(analytics.morningTasks, analytics.afternoonTasks, analytics.eveningTasks)
    }
}

// MARK: - Fun Fact Card
struct FunFactCard: View {
    let emoji: String
    let fact: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 28))
            
            Text(fact)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(description)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Time Analysis Section
struct TimeAnalysisSection: View {
    let analytics: WeeklyAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⏰ Análisis Temporal")
                .font(.headline)
            
            HStack(spacing: 12) {
                TimeCard(
                    period: "Mañana",
                    emoji: "🌅",
                    count: analytics.morningTasks,
                    color: .orange
                )
                
                TimeCard(
                    period: "Tarde",
                    emoji: "☀️",
                    count: analytics.afternoonTasks,
                    color: .yellow
                )
                
                TimeCard(
                    period: "Noche",
                    emoji: "🌙",
                    count: analytics.eveningTasks,
                    color: .indigo
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Time Card
struct TimeCard: View {
    let period: String
    let emoji: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title2)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(period)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Motivation Section
struct MotivationSection: View {
    let analytics: WeeklyAnalytics
    
    var body: some View {
        VStack(spacing: 16) {
            Text(motivationalMessage)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            
            Text(motivationalTip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: motivationalColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(motivationalColors.first ?? .blue, lineWidth: 1)
                .opacity(0.3)
        )
    }
    
    private var motivationalMessage: String {
        if analytics.averageCompletion >= 0.9 {
            return "🚀 ¡Eres imparable! Esta semana has sido increíble."
        } else if analytics.perfectDays >= 2 {
            return "⭐ ¡Excelente! Tienes \(analytics.perfectDays) días perfectos."
        } else if analytics.currentStreak >= 3 {
            return "🔥 ¡En racha! \(analytics.currentStreak) días consecutivos de progreso."
        } else if analytics.averageCompletion >= 0.6 {
            return "👍 ¡Buen trabajo! Vas por el camino correcto."
        } else {
            return "💪 ¡Cada día es una nueva oportunidad!"
        }
    }
    
    private var motivationalTip: String {
        if analytics.averageCompletion >= 0.8 {
            return "Mantén este ritmo increíble. ¡Eres una máquina de productividad!"
        } else if analytics.morningTasks > analytics.afternoonTasks + analytics.eveningTasks {
            return "Eres más productivo en las mañanas. ¡Aprovecha esa energía!"
        } else if analytics.currentStreak >= 2 {
            return "Tu consistencia es admirable. ¡No rompas la racha!"
        } else {
            return "Enfócate en completar al menos una tarea importante cada día."
        }
    }
    
    private var motivationalColors: [Color] {
        if analytics.averageCompletion >= 0.8 {
            return [.green, .blue]
        } else if analytics.currentStreak >= 3 {
            return [.orange, .red]
        } else {
            return [.blue, .purple]
        }
    }
}
