import SwiftUI
import Charts

// MARK: - Supporting Data Types
enum StatsTimeframe: String, CaseIterable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"
    
    var title: String {
        switch self {
        case .week: return "Esta Semana"
        case .month: return "Este Mes"
        case .quarter: return "Último Trimestre"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

struct PomodoroAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct PomodoroStatsView: View {
    @StateObject private var pomodoroManager = PomodoroManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTimeframe: StatsTimeframe = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con estadísticas principales
                    statsHeaderSection
                    
                    // Selector de tiempo
                    timeframePicker
                    
                    // Gráfico de sesiones
                    sessionsChartSection
                    
                    // Estadísticas detalladas
                    detailedStatsSection
                    
                    // Patrones de productividad
                    productivityPatternsSection
                    
                    // Logros
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Estadísticas Pomodoro")
            .navigationBarTitleDisplayMode(.large)
            .background(themeManager.themeColors.background)
        }
    }
    
    // MARK: - Header Section
    private var statsHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                PomodoroStatCard(
                    title: "Total Sesiones",
                    value: "\(pomodoroManager.sessions.count)",
                    subtitle: "Completadas",
                    color: .blue,
                    icon: "brain.head.profile"
                )
                
                PomodoroStatCard(
                    title: "Tiempo Total",
                    value: formatHours(pomodoroManager.totalFocusTime),
                    subtitle: "De enfoque",
                    color: .green,
                    icon: "clock.fill"
                )
            }
            
            HStack {
                PomodoroStatCard(
                    title: "Promedio Diario",
                    value: "\(averageDailySessions)",
                    subtitle: "Sesiones",
                    color: .orange,
                    icon: "calendar"
                )
                
                PomodoroStatCard(
                    title: "Racha Actual",
                    value: "\(currentStreak)",
                    subtitle: "Días",
                    color: .red,
                    icon: "flame.fill"
                )
            }
        }
    }
    
    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        HStack(spacing: 12) {
            ForEach(StatsTimeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTimeframe == timeframe ? .white : themeManager.themeColors.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedTimeframe == timeframe ?
                                themeManager.currentAccentColor :
                                themeManager.themeColors.surface,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(themeManager.themeColors.border, lineWidth: selectedTimeframe == timeframe ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Sessions Chart
    private var sessionsChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sesiones por Día")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Fecha", dataPoint.date),
                    y: .value("Sesiones", dataPoint.sessions)
                )
                .foregroundStyle(themeManager.currentAccentColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeframe.days / 7))) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text("\(Int(value.as(Double.self) ?? 0))")
                            .font(.caption2)
                    }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Detailed Stats
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detalles por Tipo de Sesión")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            VStack(spacing: 12) {
                ForEach(PomodoroSessionType.allCases, id: \.self) { sessionType in
                    SessionTypeStatsRow(
                        type: sessionType,
                        sessions: getSessionsCount(for: sessionType),
                        totalTime: getTotalTime(for: sessionType)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Productivity Patterns
    private var productivityPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patrones de Productividad")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            VStack(spacing: 12) {
                PatternInsightRow(
                    title: "Mejor Hora del Día",
                    value: bestTimeOfDay,
                    icon: "clock.badge.checkmark"
                )
                
                PatternInsightRow(
                    title: "Día Más Productivo",
                    value: mostProductiveDay,
                    icon: "calendar.badge.checkmark"
                )
                
                PatternInsightRow(
                    title: "Sesión Promedio",
                    value: "\(Int(averageSessionDuration / 60)) min",
                    icon: "timer"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏆 Logros Pomodoro")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(pomodoroAchievements, id: \.title) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    private var chartData: [PomodoroChartData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var data: [PomodoroChartData] = []
        
        for i in (1...selectedTimeframe.days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let sessions = pomodoroManager.getSessionsForDate(date)
            
            data.append(PomodoroChartData(
                date: date,
                sessions: sessions.count,
                focusTime: sessions.filter { $0.type == .work }.reduce(0) { $0 + $1.duration }
            ))
        }
        
        return data
    }
    
    private var averageDailySessions: Int {
        let totalSessions = pomodoroManager.sessions.count
        let daysWithSessions = Set(pomodoroManager.sessions.map {
            Calendar.current.startOfDay(for: $0.startTime)
        }).count
        return daysWithSessions > 0 ? totalSessions / daysWithSessions : 0
    }
    
    private var currentStreak: Int {
        // Calcular racha actual de días con al menos una sesión
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let sessionsForDay = pomodoroManager.getSessionsForDate(currentDate)
            if sessionsForDay.isEmpty {
                break
            }
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private var bestTimeOfDay: String {
        let hourCounts = Dictionary(grouping: pomodoroManager.sessions) { session in
            Calendar.current.component(.hour, from: session.startTime)
        }.mapValues { $0.count }
        
        if let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            return "\(bestHour):00"
        }
        return "N/A"
    }
    
    private var mostProductiveDay: String {
        let dayCounts = Dictionary(grouping: pomodoroManager.sessions) { session in
            Calendar.current.component(.weekday, from: session.startTime)
        }.mapValues { $0.count }
        
        if let bestDay = dayCounts.max(by: { $0.value < $1.value })?.key {
            let dayNames = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
            return dayNames[bestDay - 1]
        }
        return "N/A"
    }
    
    private var averageSessionDuration: TimeInterval {
        let totalDuration = pomodoroManager.sessions.reduce(0) { $0 + $1.duration }
        return pomodoroManager.sessions.isEmpty ? 0 : totalDuration / Double(pomodoroManager.sessions.count)
    }
    
    private var pomodoroAchievements: [PomodoroAchievement] {
        var achievements: [PomodoroAchievement] = []
        
        // First session
        if pomodoroManager.sessions.count >= 1 {
            achievements.append(PomodoroAchievement(
                title: "Primera Sesión",
                description: "Completaste tu primera sesión Pomodoro",
                icon: "play.circle.fill",
                color: .green,
                isUnlocked: true
            ))
        }
        
        // Focused Worker (10 sessions)
        if pomodoroManager.sessions.filter({ $0.type == .work }).count >= 10 {
            achievements.append(PomodoroAchievement(
                title: "Trabajador Enfocado",
                description: "10 sesiones de trabajo completadas",
                icon: "brain.head.profile",
                color: .blue,
                isUnlocked: true
            ))
        }
        
        // Marathon (4 hours in one day)
        let maxDailyTime = pomodoroManager.sessions
            .grouped(by: { Calendar.current.startOfDay(for: $0.startTime) })
            .values
            .map { sessions in sessions.filter { $0.type == .work }.reduce(0) { $0 + $1.duration } }
            .max() ?? 0
        
        if maxDailyTime >= 4 * 3600 {
            achievements.append(PomodoroAchievement(
                title: "Maratonista",
                description: "4+ horas de enfoque en un día",
                icon: "timer",
                color: .red,
                isUnlocked: true
            ))
        }
        
        // Consistent (7 day streak)
        if currentStreak >= 7 {
            achievements.append(PomodoroAchievement(
                title: "Consistente",
                description: "7 días consecutivos con sesiones",
                icon: "flame.fill",
                color: .orange,
                isUnlocked: true
            ))
        }
        
        return achievements
    }
    
    // MARK: - Helper Methods
    private func getSessionsCount(for type: PomodoroSessionType) -> Int {
        pomodoroManager.sessions.filter { $0.type == type }.count
    }
    
    private func getTotalTime(for type: PomodoroSessionType) -> TimeInterval {
        pomodoroManager.sessions
            .filter { $0.type == type }
            .reduce(0) { $0 + $1.duration }
    }
    
    private func formatHours(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views
struct PomodoroStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PomodoroChartData: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: Int
    let focusTime: TimeInterval
}

struct SessionTypeStatsRow: View {
    let type: PomodoroSessionType
    let sessions: Int
    let totalTime: TimeInterval
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text("\(sessions) sesiones")
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
            }
            
            Spacer()
            
            Text(formatTime(totalTime))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(type.color)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct PatternInsightRow: View {
    let title: String
    let value: String
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(themeManager.currentAccentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.currentAccentColor)
        }
        .padding(.vertical, 4)
    }
}

struct AchievementCard: View {
    let achievement: PomodoroAchievement
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(achievement.isUnlocked ? achievement.color : themeManager.themeColors.secondary)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(achievement.isUnlocked ? themeManager.themeColors.primary : themeManager.themeColors.secondary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(themeManager.themeColors.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? achievement.color.opacity(0.1) : themeManager.themeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            achievement.isUnlocked ? achievement.color.opacity(0.3) : themeManager.themeColors.border,
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Extensions
extension Array {
    func grouped<Key: Hashable>(by keyPath: (Element) -> Key) -> [Key: [Element]] {
        return Dictionary(grouping: self, by: keyPath)
    }
}

#Preview {
    PomodoroStatsView()
}
