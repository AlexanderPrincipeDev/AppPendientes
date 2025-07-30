import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var model: ChoreModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Summary Card
                    TodaySummaryCard()
                    
                    // Weekly Progress Chart
                    WeeklyProgressChart()
                    
                    // Category Breakdown
                    CategoryBreakdown()
                    
                    // Recent Activity
                    RecentActivity()
                }
                .padding()
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Today's Summary Card
struct TodaySummaryCard: View {
    @EnvironmentObject var model: ChoreModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hoy")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Date().formatted(.dateTime.weekday(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            let todayRecord = model.todayRecord
            let completionRate = todayRecord.completionRate
            
            CircularProgressView(
                progress: completionRate,
                completed: todayRecord.completedCount,
                total: todayRecord.totalCount
            )
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let completed: Int
    let total: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("\(completed) de \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Weekly Progress Chart
struct WeeklyProgressChart: View {
    @EnvironmentObject var model: ChoreModel
    
    private var weeklyData: [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let dateString = date.asDateString()
            let rate = model.completionRate(for: dateString)
            return WeekDay(day: date.formatted(.dateTime.weekday(.abbreviated)), rate: rate, date: date)
        }.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progreso Semanal")
                .font(.headline)
            
            Chart(weeklyData) { item in
                BarMark(
                    x: .value("Día", item.day),
                    y: .value("Completado", item.rate)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WeekDay: Identifiable {
    let id = UUID()
    let day: String
    let rate: Double
    let date: Date
}

// MARK: - Category Breakdown
struct CategoryBreakdown: View {
    @EnvironmentObject var model: ChoreModel
    
    private var categoryStats: [CategoryStat] {
        var stats: [CategoryStat] = []
        
        for category in model.categories {
            let tasksInCategory = model.tasks.filter { $0.categoryId == category.id }
            let completedToday = tasksInCategory.filter { task in
                model.isTaskCompletedToday(task.id)
            }.count
            
            if !tasksInCategory.isEmpty {
                stats.append(CategoryStat(
                    category: category,
                    completed: completedToday,
                    total: tasksInCategory.count
                ))
            }
        }
        
        // Add uncategorized tasks
        let uncategorizedTasks = model.tasks.filter { $0.categoryId == nil }
        if !uncategorizedTasks.isEmpty {
            let completedUncategorized = uncategorizedTasks.filter { task in
                model.isTaskCompletedToday(task.id)
            }.count
            
            stats.append(CategoryStat(
                category: nil,
                completed: completedUncategorized,
                total: uncategorizedTasks.count
            ))
        }
        
        return stats.sorted { $0.completionRate > $1.completionRate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Por Categoría")
                .font(.headline)
            
            ForEach(categoryStats) { stat in
                CategoryStatRow(stat: stat)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: TaskCategory?
    let completed: Int
    let total: Int
    
    var completionRate: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var name: String {
        category?.name ?? "Sin categoría"
    }
    
    var color: Color {
        category?.swiftUIColor ?? .gray
    }
    
    var icon: String {
        category?.icon ?? "circle"
    }
}

struct CategoryStatRow: View {
    let stat: CategoryStat
    
    var body: some View {
        HStack {
            Image(systemName: stat.icon)
                .foregroundStyle(stat.color)
                .frame(width: 20)
            
            Text(stat.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(stat.completed)/\(stat.total)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ProgressView(value: stat.completionRate)
                .frame(width: 60)
                .tint(stat.color)
        }
    }
}

// MARK: - Recent Activity
struct RecentActivity: View {
    @EnvironmentObject var model: ChoreModel
    
    private var recentRecords: [DailyRecord] {
        Array(model.dailyRecords.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Reciente")
                .font(.headline)
            
            ForEach(recentRecords) { record in
                RecentActivityRow(record: record)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RecentActivityRow: View {
    let record: DailyRecord
    
    private var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: record.date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date?.formatted(.dateTime.weekday(.wide)) ?? record.date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date?.formatted(.dateTime.month().day()) ?? record.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(record.completionRate * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(record.completionRate > 0.7 ? .green : record.completionRate > 0.3 ? .orange : .red)
                
                Text("\(record.completedCount)/\(record.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
