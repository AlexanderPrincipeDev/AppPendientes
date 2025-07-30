import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var selectedFilter: String = "Todas"
    @State private var selectedPeriod: String = "30 días"
    @State private var showingTaskDetail: DailyRecord?
    @State private var showingCalendarView = false
    
    private var sortedRecords: [DailyRecord] {
        let filtered = periodFilteredRecords
        return filtered.sorted { record1, record2 in
            record1.date > record2.date
        }
    }
    
    private var periodFilteredRecords: [DailyRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case "7 días":
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return model.records.filter { record in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let recordDate = formatter.date(from: record.date) {
                    return recordDate >= sevenDaysAgo
                }
                return false
            }
        case "30 días":
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            return model.records.filter { record in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let recordDate = formatter.date(from: record.date) {
                    return recordDate >= thirtyDaysAgo
                }
                return false
            }
        case "3 meses":
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return model.records.filter { record in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let recordDate = formatter.date(from: record.date) {
                    return recordDate >= threeMonthsAgo
                }
                return false
            }
        default:
            return model.records
        }
    }
    
    private var filteredRecords: [DailyRecord] {
        switch selectedFilter {
        case "Completadas 100%":
            return sortedRecords.filter { $0.completionRate == 1.0 }
        case "Con progreso":
            return sortedRecords.filter { $0.completionRate > 0 && $0.completionRate < 1.0 }
        case "Sin progreso":
            return sortedRecords.filter { $0.completionRate == 0 }
        case "Excelente (80%+)":
            return sortedRecords.filter { $0.completionRate >= 0.8 }
        default:
            return sortedRecords
        }
    }
    
    private var enhancedStats: (totalDays: Int, perfectDays: Int, averageCompletion: Double, bestStreak: Int, currentStreak: Int) {
        let records = sortedRecords
        let perfectDays = records.filter { $0.completionRate == 1.0 }.count
        let avgCompletion = records.isEmpty ? 0 : records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        
        // Calculate streaks
        let (bestStreak, currentStreak) = calculateStreaks(from: records)
        
        return (records.count, perfectDays, avgCompletion, bestStreak, currentStreak)
    }
    
    private func calculateStreaks(from records: [DailyRecord]) -> (best: Int, current: Int) {
        let perfectRecords = records.filter { $0.completionRate == 1.0 }
        guard !perfectRecords.isEmpty else { return (0, 0) }
        
        let sortedDates = perfectRecords.compactMap { record -> Date? in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: record.date)
        }.sorted()
        
        var bestStreak = 0
        var currentStreak = 0
        var tempStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = Calendar.current.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            
            if daysBetween == 1 {
                tempStreak += 1
            } else {
                bestStreak = max(bestStreak, tempStreak)
                tempStreak = 1
            }
        }
        
        bestStreak = max(bestStreak, tempStreak)
        
        // Calculate current streak
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        if let todayRecord = records.first(where: { $0.date == todayString }),
           todayRecord.completionRate == 1.0 {
            currentStreak = 1
            
            for i in 1..<records.count {
                let dayDate = Calendar.current.date(byAdding: .day, value: -i, to: today)!
                let dayString = formatter.string(from: dayDate)
                
                if let dayRecord = records.first(where: { $0.date == dayString }),
                   dayRecord.completionRate == 1.0 {
                    currentStreak += 1
                } else {
                    break
                }
            }
        }
        
        return (bestStreak, currentStreak)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Header with Statistics
                    EnhancedHistoryStatsHeaderView(stats: enhancedStats, onCalendarTap: {
                        showingCalendarView = true
                    })
                    
                    // Period and Filter Controls
                    VStack(spacing: 12) {
                        HistoryPeriodSelectorView(selectedPeriod: $selectedPeriod)
                        HistoryFilterSectionView(selectedFilter: $selectedFilter)
                    }
                    
                    // Records List with Enhanced Design
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRecords) { record in
                            EnhancedHistoryDayCardView(record: record, model: model) {
                                showingTaskDetail = record
                            }
                        }
                        
                        if filteredRecords.isEmpty {
                            EnhancedEmptyHistoryStateView(selectedFilter: selectedFilter)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $showingTaskDetail) { record in
                EnhancedDayDetailSheetView(record: record, model: model)
                    .presentationDetents([.height(600), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCalendarView) {
                CalendarHistoryView(model: model, onDaySelected: { record in
                    showingCalendarView = false
                    showingTaskDetail = record
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Enhanced History Stats Header
struct EnhancedHistoryStatsHeaderView: View {
    let stats: (totalDays: Int, perfectDays: Int, averageCompletion: Double, bestStreak: Int, currentStreak: Int)
    let onCalendarTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resumen de actividad")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Estadísticas de tu progreso")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onCalendarTap) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(.blue.opacity(0.1), in: Circle())
                }
            }
            
            // Primary Stats
            HStack(spacing: 16) {
                StatCardView(
                    icon: "calendar.badge.checkmark",
                    title: "Días activos",
                    value: "\(stats.totalDays)",
                    color: .blue,
                    isLarge: true
                )
                
                StatCardView(
                    icon: "star.circle.fill",
                    title: "Días perfectos",
                    value: "\(stats.perfectDays)",
                    color: .green,
                    isLarge: true
                )
            }
            
            // Secondary Stats
            HStack(spacing: 12) {
                StatCardView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Promedio",
                    value: "\(Int(stats.averageCompletion * 100))%",
                    color: .orange
                )
                
                StatCardView(
                    icon: "flame.fill",
                    title: "Racha actual",
                    value: "\(stats.currentStreak)",
                    color: .red
                )
                
                StatCardView(
                    icon: "trophy.fill",
                    title: "Mejor racha",
                    value: "\(stats.bestStreak)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Enhanced Stat Card
struct StatCardView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var isLarge: Bool = false
    
    var body: some View {
        VStack(spacing: isLarge ? 12 : 8) {
            Image(systemName: icon)
                .font(isLarge ? .title : .title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(isLarge ? .title2 : .title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(isLarge ? .caption : .caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isLarge ? 16 : 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Period Selector
struct HistoryPeriodSelectorView: View {
    @Binding var selectedPeriod: String
    
    private let periods = ["7 días", "30 días", "3 meses", "Todo"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(periods, id: \.self) { period in
                    PeriodChipView(
                        title: period,
                        isSelected: selectedPeriod == period
                    ) {
                        selectedPeriod = period
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Period Chip
struct PeriodChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isSelected ? .blue : Color(.systemGray6))
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced History Filter Section
struct HistoryFilterSectionView: View {
    @Binding var selectedFilter: String
    
    private let filters = ["Todas", "Completadas 100%", "Excelente (80%+)", "Con progreso", "Sin progreso"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    FilterChipView(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Enhanced Filter Chip  
struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .green : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced History Day Card
struct EnhancedHistoryDayCardView: View {
    let record: DailyRecord
    let model: ChoreModel
    let onTap: () -> Void
    
    private var completedTasks: [TaskStatus] {
        record.statuses.filter { $0.completed }
    }
    
    private var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: record.date)
    }
    
    private var daysSinceToday: Int {
        guard let date = date else { return 0 }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
    
    private var relativeTimeText: String {
        switch daysSinceToday {
        case 0: return "Hoy"
        case 1: return "Ayer"
        case 2...6: return "Hace \(daysSinceToday) días"
        case 7...13: return "Hace 1 semana"
        case 14...20: return "Hace 2 semanas"
        case 21...29: return "Hace 3 semanas"
        case 30...59: return "Hace 1 mes"
        default: return date?.shortDate ?? record.date
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Enhanced Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(date?.dayName ?? "Día")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            if record.completionRate == 1.0 {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        Text(relativeTimeText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(date?.shortDate ?? record.date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("\(Int(record.completionRate * 100))")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundStyle(progressColor)
                            
                            Text("%")
                                .font(.headline)
                                .foregroundStyle(progressColor)
                        }
                        
                        Text("\(record.completedCount)/\(record.totalCount) tareas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        performanceBadge
                    }
                }
                
                // Enhanced Progress Bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.7), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(record.completionRate) * UIScreen.main.bounds.width * 0.8, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: record.completionRate)
                }
                
                // Task Preview with Better Layout
                if !completedTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            
                            Text("Tareas completadas:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(formatCompletionTime())
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(Array(completedTasks.prefix(4).enumerated()), id: \.offset) { index, taskStatus in
                                if let task = model.tasks.first(where: { $0.id == taskStatus.taskId }) {
                                    EnhancedCompletedTaskPreviewView(task: task, model: model, completedAt: taskStatus.completedAt)
                                }
                            }
                            
                            if completedTasks.count > 4 {
                                HStack {
                                    Image(systemName: "ellipsis")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("+\(completedTasks.count - 4)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: progressColor.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var progressColor: Color {
        if record.completionRate == 1.0 {
            return .green
        } else if record.completionRate >= 0.8 {
            return .blue
        } else if record.completionRate >= 0.5 {
            return .orange
        } else if record.completionRate > 0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var performanceBadge: some View {
        Group {
            if record.completionRate == 1.0 {
                Text("Perfecto")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green, in: RoundedRectangle(cornerRadius: 12))
            } else if record.completionRate >= 0.8 {
                Text("Excelente")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            } else if record.completionRate >= 0.5 {
                Text("Bien")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 12))
            } else if record.completionRate > 0 {
                Text("Regular")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func formatCompletionTime() -> String {
        let completedTimes = completedTasks.compactMap { $0.completedAt }
        guard !completedTimes.isEmpty else { return "" }
        
        let sortedTimes = completedTimes.sorted()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if sortedTimes.count == 1 {
            return formatter.string(from: sortedTimes[0])
        } else {
            let first = formatter.string(from: sortedTimes.first!)
            let last = formatter.string(from: sortedTimes.last!)
            return "\(first) - \(last)"
        }
    }
}

// MARK: - Enhanced Completed Task Preview
struct EnhancedCompletedTaskPreviewView: View {
    let task: TaskItem
    let model: ChoreModel
    let completedAt: Date?
    
    var body: some View {
        HStack(spacing: 8) {
            if let category = model.getCategoryForTask(task) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(category.swiftUIColor)
                    .frame(width: 16)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .frame(width: 16)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                if let completedAt = completedAt {
                    Text(formatTime(completedAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Day Detail Sheet
struct EnhancedDayDetailSheetView: View {
    let record: DailyRecord
    let model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    
    private var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: record.date)
    }
    
    private var completedTasks: [TaskStatus] {
        record.statuses.filter { $0.completed }.sorted { status1, status2 in
            guard let time1 = status1.completedAt, let time2 = status2.completedAt else {
                return status1.completedAt != nil
            }
            return time1 < time2
        }
    }
    
    private var incompleteTasks: [TaskStatus] {
        record.statuses.filter { !$0.completed }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(date?.dayName ?? "Día")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text(date?.shortDate ?? record.date)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if record.completionRate == 1.0 {
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        // Enhanced Progress Circle
                        ZStack {
                            Circle()
                                .stroke(.quaternary, lineWidth: 16)
                            
                            Circle()
                                .trim(from: 0, to: record.completionRate)
                                .stroke(
                                    LinearGradient(
                                        colors: [progressColor.opacity(0.7), progressColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), 
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: record.completionRate)
                            
                            VStack(spacing: 6) {
                                Text("\(Int(record.completionRate * 100))%")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(progressColor)
                                
                                Text("\(record.completedCount)/\(record.totalCount)")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text("tareas")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(width: 140, height: 140)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    
                    // Enhanced Task Sections
                    if !completedTasks.isEmpty {
                        EnhancedTaskDetailSectionView(
                            title: "Completadas (\(completedTasks.count))",
                            icon: "checkmark.seal.fill",
                            color: .green,
                            tasks: completedTasks,
                            model: model,
                            showCompletionTime: true
                        )
                    }
                    
                    if !incompleteTasks.isEmpty {
                        EnhancedTaskDetailSectionView(
                            title: "No completadas (\(incompleteTasks.count))",
                            icon: "circle.dashed",
                            color: .red,
                            tasks: incompleteTasks,
                            model: model,
                            showCompletionTime: false
                        )
                    }
                    
                    if completedTasks.isEmpty && incompleteTasks.isEmpty {
                        Text("No hay tareas registradas para este día")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Detalle del día")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var progressColor: Color {
        if record.completionRate == 1.0 {
            return .green
        } else if record.completionRate >= 0.8 {
            return .blue
        } else if record.completionRate >= 0.5 {
            return .orange
        } else if record.completionRate > 0 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Enhanced Task Detail Section
struct EnhancedTaskDetailSectionView: View {
    let title: String
    let icon: String
    let color: Color
    let tasks: [TaskStatus]
    let model: ChoreModel
    let showCompletionTime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(tasks, id: \.taskId) { taskStatus in
                    if let task = model.tasks.first(where: { $0.id == taskStatus.taskId }) {
                        EnhancedTaskDetailRowView(
                            task: task,
                            taskStatus: taskStatus,
                            model: model,
                            showCompletionTime: showCompletionTime
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Enhanced Task Detail Row
struct EnhancedTaskDetailRowView: View {
    let task: TaskItem
    let taskStatus: TaskStatus
    let model: ChoreModel
    let showCompletionTime: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon with Better Styling
            Group {
                if let category = model.getCategoryForTask(task) {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.swiftUIColor)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: taskStatus.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(taskStatus.completed ? .green : .gray)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
            }
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
            )
            
            // Task Information
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(taskStatus.completed)
                    .foregroundStyle(taskStatus.completed ? .secondary : .primary)
                
                if let category = model.getCategoryForTask(task) {
                    Text(category.name)
                        .font(.caption)
                        .foregroundStyle(category.swiftUIColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(category.swiftUIColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Spacer()
            
            // Completion Time with Better Styling
            if showCompletionTime, let completedAt = taskStatus.completedAt {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(completedAt))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("completada")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Empty History State
struct EnhancedEmptyHistoryStateView: View {
    let selectedFilter: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case "Completadas 100%":
            return "star.circle"
        case "Con progreso":
            return "chart.line.uptrend.xyaxis"
        case "Sin progreso":
            return "exclamationmark.circle"
        case "Excelente (80%+)":
            return "trophy.circle"
        default:
            return "calendar.badge.clock"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case "Completadas 100%":
            return "Sin días perfectos"
        case "Con progreso":
            return "Sin días con progreso parcial"
        case "Sin progreso":
            return "¡Qué bien!"
        case "Excelente (80%+)":
            return "Sin días excelentes"
        default:
            return "Sin historial"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case "Completadas 100%":
            return "Aún no tienes días donde hayas completado todas las tareas. ¡Sigue esforzándote!"
        case "Con progreso":
            return "No hay días con progreso parcial en este período."
        case "Sin progreso":
            return "No tienes días sin progreso. ¡Excelente trabajo!"
        case "Excelente (80%+)":
            return "Aún no tienes días con 80% o más de completado. ¡Puedes lograrlo!"
        default:
            return "Cuando completes tareas, aparecerán aquí organizadas por día."
        }
    }
}

// MARK: - Calendar History View
struct CalendarHistoryView: View {
    let model: ChoreModel
    let onDaySelected: (DailyRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Vista de calendario próximamente...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding()
                    
                    // Aquí podrías implementar una vista de calendario personalizada
                    // Por ahora mostramos una lista simplificada por mes
                    
                    ForEach(groupedRecordsByMonth.keys.sorted(by: >), id: \.self) { month in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(month)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(groupedRecordsByMonth[month] ?? [], id: \.id) { record in
                                    CalendarDayView(record: record) {
                                        onDaySelected(record)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Historial por mes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var groupedRecordsByMonth: [String: [DailyRecord]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_ES")
        monthFormatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: model.records) { record in
            if let date = formatter.date(from: record.date) {
                return monthFormatter.string(from: date).capitalized
            }
            return "Desconocido"
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let record: DailyRecord
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: record.date) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            return dayFormatter.string(from: date)
        }
        return "?"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Circle()
                    .fill(progressColor)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(record.completionRate > 0 ? progressColor.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var progressColor: Color {
        if record.completionRate == 1.0 {
            return .green
        } else if record.completionRate >= 0.8 {
            return .blue
        } else if record.completionRate >= 0.5 {
            return .orange
        } else if record.completionRate > 0 {
            return .yellow
        } else {
            return .gray
        }
    }
}
