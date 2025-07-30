import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var selectedTimeframe = StatsTimeframe.week
    @State private var showingDetailedStats = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section with Key Metrics
                    StatsHeroSection()
                    
                    // Time Filter Picker
                    TimeframePicker(selectedTimeframe: $selectedTimeframe)
                    
                    // Main Chart Section
                    MainChartSection(timeframe: selectedTimeframe)
                    
                    // Quick Insights Grid
                    QuickInsightsGrid(timeframe: selectedTimeframe)
                    
                    // Category Analysis
                    CategoryAnalysisSection(timeframe: selectedTimeframe)
                    
                    // Achievement Section
                    AchievementsSection()
                }
                .padding()
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDetailedStats = true
                    }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingDetailedStats) {
                DetailedStatsView()
                    .environmentObject(model)
            }
        }
    }
}

// MARK: - Enums
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

// MARK: - Stats Hero Section
struct StatsHeroSection: View {
    @EnvironmentObject var model: ChoreModel
    
    private var todayStats: (completed: Int, total: Int, rate: Double) {
        let record = model.todayRecord
        return (record.completedCount, record.totalCount, record.completionRate)
    }
    
    private var weekStats: (avg: Double, trend: Double, streak: Int) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var weekRates: [Double] = []
        var streak = 0
        
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                weekRates.append(record.completionRate)
                if record.completionRate > 0.7 {
                    streak += 1
                }
            }
        }
        
        let average = weekRates.isEmpty ? 0 : weekRates.reduce(0, +) / Double(weekRates.count)
        let trend = weekRates.count >= 2 ? weekRates.last! - weekRates.first! : 0
        
        return (average, trend, streak)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Main circular progress
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: todayStats.rate)
                    .stroke(
                        LinearGradient(
                            colors: progressGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: todayStats.rate)
                
                VStack(spacing: 4) {
                    Text("\(Int(todayStats.rate * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Hoy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stats cards row
            HStack(spacing: 16) {
                StatCard(
                    title: "Completadas",
                    value: "\(todayStats.completed)",
                    subtitle: "de \(todayStats.total)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Promedio Semanal",
                    value: "\(Int(weekStats.avg * 100))%",
                    subtitle: trendText,
                    color: weekStats.trend >= 0 ? .blue : .orange,
                    icon: weekStats.trend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                )
                
                StatCard(
                    title: "Racha",
                    value: "\(weekStats.streak)",
                    subtitle: "días activos",
                    color: .red,
                    icon: "flame.fill"
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
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
    
    private var progressGradient: [Color] {
        if todayStats.rate >= 0.8 {
            return [.green, .mint]
        } else if todayStats.rate >= 0.5 {
            return [.blue, .cyan]
        } else {
            return [.orange, .yellow]
        }
    }
    
    private var trendText: String {
        let trend = weekStats.trend
        if abs(trend) < 0.05 {
            return "estable"
        } else if trend > 0 {
            return "↗️ mejorando"
        } else {
            return "↘️ bajando"
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(color)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Timeframe Picker
struct TimeframePicker: View {
    @Binding var selectedTimeframe: StatsTimeframe
    
    var body: some View {
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
                        .foregroundStyle(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedTimeframe == timeframe ?
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(.quaternary, lineWidth: selectedTimeframe == timeframe ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Main Chart Section
struct MainChartSection: View {
    @EnvironmentObject var model: ChoreModel
    let timeframe: StatsTimeframe
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var data: [ChartDataPoint] = []
        
        for i in (1...timeframe.days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }) {
                let value = record.completionRate * 100
                
                data.append(ChartDataPoint(
                    date: date,
                    value: value,
                    label: dateString
                ))
            } else {
                data.append(ChartDataPoint(
                    date: date,
                    value: 0,
                    label: dateString
                ))
            }
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tendencia de \(timeframe.title)")
                    .font(.headline)
                
                Spacer()
                
                Text("Promedio: \(Int(chartData.map(\.value).reduce(0, +) / Double(chartData.count)))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart(chartData) { dataPoint in
                LineMark(
                    x: .value("Fecha", dataPoint.date),
                    y: .value("Valor", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Fecha", dataPoint.date),
                    y: .value("Valor", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, timeframe.days / 7))) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text("\(Int(value.as(Double.self) ?? 0))%")
                            .font(.caption2)
                    }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

// MARK: - Quick Insights Grid
struct QuickInsightsGrid: View {
    @EnvironmentObject var model: ChoreModel
    let timeframe: StatsTimeframe
    
    private var insights: [InsightData] {
        calculateInsights()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Insights Rápidos")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
    
    private func calculateInsights() -> [InsightData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var totalTasks = 0
        var completedTasks = 0
        var perfectDays = 0
        var activeDays = 0
        
        for i in 1...timeframe.days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.totalCount > 0 {
                activeDays += 1
                totalTasks += record.totalCount
                completedTasks += record.completedCount
                
                if record.completionRate == 1.0 {
                    perfectDays += 1
                }
            }
        }
        
        let efficiency = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        let consistency = activeDays > 0 ? Double(perfectDays) / Double(activeDays) : 0
        
        return [
            InsightData(
                title: "Eficiencia",
                value: "\(Int(efficiency * 100))%",
                description: "\(completedTasks) de \(totalTasks) tareas",
                color: efficiency >= 0.8 ? .green : efficiency >= 0.6 ? .blue : .orange,
                icon: "target"
            ),
            InsightData(
                title: "Consistencia",
                value: "\(Int(consistency * 100))%",
                description: "\(perfectDays) días perfectos",
                color: consistency >= 0.5 ? .purple : consistency >= 0.3 ? .blue : .gray,
                icon: "calendar.badge.checkmark"
            ),
            InsightData(
                title: "Días Activos",
                value: "\(activeDays)",
                description: "de \(timeframe.days) días",
                color: activeDays >= timeframe.days * 2/3 ? .green : .orange,
                icon: "chart.bar.fill"
            ),
            InsightData(
                title: "Promedio Diario",
                value: "\(activeDays > 0 ? completedTasks / activeDays : 0)",
                description: "tareas por día",
                color: .blue,
                icon: "calendar"
            )
        ]
    }
}

// MARK: - Insight Data
struct InsightData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let description: String
    let color: Color
    let icon: String
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: InsightData
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(insight.color)
            
            Text(insight.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(insight.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(insight.description)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(insight.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Analysis Section
struct CategoryAnalysisSection: View {
    @EnvironmentObject var model: ChoreModel
    let timeframe: StatsTimeframe
    
    private var categoryStats: [StatsCategoryStat] {
        calculateCategoryStats()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏷️ Análisis por Categoría")
                .font(.headline)
            
            if categoryStats.isEmpty {
                EmptyCategoryState()
            } else {
                ForEach(categoryStats.prefix(5)) { stat in
                    StatsCategoryStatRow(stat: stat)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func calculateCategoryStats() -> [StatsCategoryStat] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var categoryData: [String: (completed: Int, total: Int)] = [:]
        
        for i in 1...timeframe.days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }) {
                for status in record.statuses {
                    if let task = model.tasks.first(where: { $0.id == status.taskId }) {
                        let categoryName = model.getCategoryForTask(task)?.name ?? "Sin categoría"
                        
                        if categoryData[categoryName] == nil {
                            categoryData[categoryName] = (0, 0)
                        }
                        
                        categoryData[categoryName]!.total += 1
                        if status.completed {
                            categoryData[categoryName]!.completed += 1
                        }
                    }
                }
            }
        }
        
        return categoryData.map { name, data in
            let rate = data.total > 0 ? Double(data.completed) / Double(data.total) : 0
            return StatsCategoryStat(
                name: name,
                completed: data.completed,
                total: data.total,
                completionRate: rate,
                color: getCategoryColor(name)
            )
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    private func getCategoryColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "casa": return .orange
        case "trabajo": return .blue
        case "personal": return .purple
        case "salud": return .red
        case "ejercicio": return .green
        case "estudio": return .indigo
        case "compras": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Stats Category Stat
struct StatsCategoryStat: Identifiable {
    let id = UUID()
    let name: String
    let completed: Int
    let total: Int
    let completionRate: Double
    let color: Color
}

// MARK: - Stats Category Stat Row
struct StatsCategoryStatRow: View {
    let stat: StatsCategoryStat
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stat.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(stat.completed) de \(stat.total) tareas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(stat.completionRate * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(stat.color)
                
                ProgressView(value: stat.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: stat.color))
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Category State
struct EmptyCategoryState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("Sin datos de categorías")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Completa algunas tareas para ver el análisis")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    @EnvironmentObject var model: ChoreModel
    
    private var achievements: [StatsAchievement] {
        calculateAchievements()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏆 Logros Recientes")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func calculateAchievements() -> [StatsAchievement] {
        var achievements: [StatsAchievement] = []
        
        // Verificar días perfectos consecutivos
        let perfectStreak = calculatePerfectStreak()
        if perfectStreak >= 3 {
            achievements.append(StatsAchievement(
                title: "Racha Perfecta",
                description: "\(perfectStreak) días consecutivos al 100%",
                icon: "flame.fill",
                color: .red,
                isUnlocked: true
            ))
        }
        
        // Verificar total de tareas completadas
        let totalCompleted = model.records.reduce(0) { $0 + $1.completedCount }
        if totalCompleted >= 100 {
            achievements.append(StatsAchievement(
                title: "Centenario",
                description: "100+ tareas completadas",
                icon: "100.circle.fill",
                color: .gold,
                isUnlocked: true
            ))
        }
        
        // Verificar consistencia semanal
        if calculateWeeklyConsistency() >= 0.8 {
            achievements.append(StatsAchievement(
                title: "Constante",
                description: "80%+ de consistencia semanal",
                icon: "calendar.badge.checkmark",
                color: .blue,
                isUnlocked: true
            ))
        }
        
        // Agregar logros bloqueados si hay pocos desbloqueados
        while achievements.count < 3 {
            achievements.append(StatsAchievement(
                title: "Próximo Objetivo",
                description: "Sigue completando tareas",
                icon: "lock.fill",
                color: .gray,
                isUnlocked: false
            ))
        }
        
        return achievements
    }
    
    private func calculatePerfectStreak() -> Int {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var streak = 0
        for i in 1...30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { break }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.completionRate == 1.0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateWeeklyConsistency() -> Double {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var activeDays = 0
        for i in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if let record = model.records.first(where: { $0.date == dateString }), record.completionRate > 0.5 {
                activeDays += 1
            }
        }
        
        return Double(activeDays) / 7.0
    }
}

// MARK: - Stats Achievement
struct StatsAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: StatsAchievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundStyle(achievement.isUnlocked ? achievement.color : .secondary)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding(12)
        .background(
            achievement.isUnlocked ?
                achievement.color.opacity(0.1) :
                Color.secondary.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    achievement.isUnlocked ?
                        achievement.color.opacity(0.3) :
                        Color.secondary.opacity(0.2),
                    lineWidth: 1
                )
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.9)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Detailed Stats View
struct DetailedStatsView: View {
    @EnvironmentObject var model: ChoreModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Vista de estadísticas detalladas")
                        .font(.title2)
                    
                    Text("Próximamente: Gráficos avanzados, comparaciones históricas, y análisis profundo de patrones de productividad.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("Estadísticas Detalladas")
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
}

// MARK: - Color Extension
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    StatsView()
        .environmentObject(ChoreModel())
}
