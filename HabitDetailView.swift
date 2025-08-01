import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingEditHabit = false
    @State private var showingDeleteAlert = false
    
    private var habitStreak: HabitStreak? {
        model.getHabitStreak(habitId: habit.id)
    }
    
    private var recentEntries: [HabitEntry] {
        model.getHabitEntries(habitId: habit.id, days: 30)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con información del hábito
                    HabitDetailHeader(habit: habit)
                    
                    // Estadísticas principales
                    HabitStatsSection(habit: habit, streak: habitStreak)
                    
                    // Calendario visual de progreso
                    HabitCalendarView(habit: habit, entries: recentEntries)
                    
                    // Gráfico de progreso semanal
                    HabitWeeklyProgressChart(habit: habit, entries: recentEntries)
                    
                    // Estadísticas adicionales
                    HabitAdditionalStats(habit: habit, entries: recentEntries)
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingEditHabit = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(themeManager.currentAccentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditHabit) {
            EditHabitView(habit: habit)
        }
        .alert("Eliminar Hábito", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                model.deleteHabit(habitId: habit.id)
                dismiss()
            }
        } message: {
            Text("Esta acción no se puede deshacer. Se eliminarán todos los datos del hábito.")
        }
        .themedAccent()
    }
}

// MARK: - Habit Detail Header
struct HabitDetailHeader: View {
    let habit: Habit
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    private var isCompletedToday: Bool {
        model.isHabitCompletedToday(habitId: habit.id)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Icono grande del hábito
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(habit.color.color)
            }
            
            // Información del hábito
            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: habit.category.icon)
                        .font(.caption)
                    Text(habit.category.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(habit.category.color.opacity(0.15))
                )
                .foregroundStyle(habit.category.color)
                
                Text("Meta: \(habit.target) \(habit.unit)")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                // Botón de completar hoy
                Button {
                    HapticManager.shared.lightImpact()
                    model.toggleHabitCompletion(habitId: habit.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.headline)
                        
                        Text(isCompletedToday ? "Completado hoy" : "Marcar como hecho")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(isCompletedToday ? habit.color.color : themeManager.themeColors.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Habit Stats Section
struct HabitStatsSection: View {
    let habit: Habit
    let streak: HabitStreak?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Estadísticas")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Racha actual
                StatCard(
                    title: "Racha Actual",
                    value: "\(streak?.currentStreak ?? 0)",
                    subtitle: "días",
                    icon: "flame.fill",
                    color: .orange
                )
                
                // Racha máxima
                StatCard(
                    title: "Mejor Racha",
                    value: "\(streak?.longestStreak ?? 0)",
                    subtitle: "días",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                // Total completados
                StatCard(
                    title: "Total",
                    value: "\(streak?.totalCompletions ?? 0)",
                    subtitle: "veces",
                    icon: "checkmark.seal.fill",
                    color: habit.color.color
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(themeManager.themeColors.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Habit Calendar View
struct HabitCalendarView: View {
    let habit: Habit
    let entries: [HabitEntry]
    @StateObject private var themeManager = ThemeManager.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Últimos 30 días")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
                
                // Leyenda
                HStack(spacing: 12) {
                    LegendItem(color: habit.color.color, label: "Completado")
                    LegendItem(color: themeManager.themeColors.surface, label: "Pendiente")
                }
            }
            
            // Días de la semana
            HStack {
                ForEach(["D", "L", "M", "M", "J", "V", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.themeColors.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid de días
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.date) { dayData in
                    DayCell(
                        isCompleted: dayData.isCompleted,
                        isToday: dayData.isToday,
                        color: habit.color.color
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    private var calendarDays: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        
        var days: [DayData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Crear diccionario de entradas por fecha para búsqueda rápida
        let entriesByDate = Dictionary(grouping: entries) { $0.date }
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: thirtyDaysAgo) {
                let dateString = dateFormatter.string(from: date)
                let isCompleted = entriesByDate[dateString]?.first?.isCompleted ?? false
                let isToday = calendar.isDate(date, inSameDayAs: today)
                
                days.append(DayData(
                    date: dateString,
                    isCompleted: isCompleted,
                    isToday: isToday
                ))
            }
        }
        
        return days
    }
}

struct DayData {
    let date: String
    let isCompleted: Bool
    let isToday: Bool
}

struct DayCell: View {
    let isCompleted: Bool
    let isToday: Bool
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isCompleted ? color : themeManager.themeColors.surface)
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isToday ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isToday)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(themeManager.themeColors.secondary)
        }
    }
}

// MARK: - Weekly Progress Chart
struct HabitWeeklyProgressChart: View {
    let habit: Habit
    let entries: [HabitEntry]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progreso Semanal")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            // Chart simple con barras
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.week) { weekData in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.color.color.opacity(0.8))
                            .frame(width: 32, height: max(4, CGFloat(weekData.completedDays) * 12))
                            .animation(.easeInOut(duration: 0.6), value: weekData.completedDays)
                        
                        Text("S\(weekData.week)")
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                    }
                }
            }
            .frame(height: 100)
            
            HStack {
                Text("Días completados por semana")
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
    
    private var weeklyData: [WeekData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var weeks: [WeekData] = []
        
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) ?? Date()
            let completedDays = entries.filter { entry in
                guard let entryDate = dateFormatter.date(from: entry.date) else { return false }
                let weekOfEntry = calendar.dateInterval(of: .weekOfYear, for: entryDate)
                let weekOfStart = calendar.dateInterval(of: .weekOfYear, for: weekStart)
                return weekOfEntry == weekOfStart && entry.isCompleted
            }.count
            
            weeks.append(WeekData(week: 4 - weekOffset, completedDays: completedDays))
        }
        
        return weeks.reversed()
    }
}

struct WeekData {
    let week: Int
    let completedDays: Int
}

// MARK: - Additional Stats
struct HabitAdditionalStats: View {
    let habit: Habit
    let entries: [HabitEntry]
    @StateObject private var themeManager = ThemeManager.shared
    
    private var completionRate: Double {
        guard !entries.isEmpty else { return 0.0 }
        let completedEntries = entries.filter { $0.isCompleted }.count
        return Double(completedEntries) / Double(entries.count)
    }
    
    private var bestDay: String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        var dayCount: [String: Int] = [:]
        
        for entry in entries.filter({ $0.isCompleted }) {
            if let date = dayFormatter.date(from: entry.date) {
                let dayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
                dayCount[dayName, default: 0] += 1
            }
        }
        
        return dayCount.max(by: { $0.value < $1.value })?.key ?? "Ninguno"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Análisis")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Tasa de cumplimiento
                HStack {
                    Text("Tasa de cumplimiento")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(habit.color.color)
                }
                
                // Barra de progreso
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.themeColors.surface)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.color.color)
                            .frame(width: geometry.size.width * completionRate, height: 8)
                            .animation(.easeInOut(duration: 0.8), value: completionRate)
                    }
                }
                .frame(height: 8)
                
                // Mejor día
                HStack {
                    Text("Mejor día de la semana")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Spacer()
                    
                    Text(bestDay)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.themeColors.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
}

#Preview {
    HabitDetailView(habit: Habit.presetHabits[0])
        .environmentObject(ChoreModel())
}