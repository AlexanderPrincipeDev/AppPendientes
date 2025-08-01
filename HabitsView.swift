import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingAddHabit = false
    @State private var showingHabitDetail: Habit?
    @State private var selectedHabitCategory: HabitCategory? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header con estadísticas del día
                    HabitDayStatsCard()
                    
                    // Filtros por categoría
                    HabitCategoryFilter(selectedCategory: $selectedHabitCategory)
                    
                    // Lista de hábitos
                    if filteredHabits.isEmpty {
                        HabitEmptyState(selectedCategory: selectedHabitCategory) {
                            showingAddHabit = true
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredHabits) { habit in
                                HabitCard(habit: habit) {
                                    showingHabitDetail = habit
                                }
                            }
                        }
                    }
                    
                    // Espaciado final
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Hábitos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeManager.currentAccentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(item: $showingHabitDetail) { habit in
            HabitDetailView(habit: habit)
        }
        .themedAccent()
    }
    
    private var filteredHabits: [Habit] {
        let activeHabits = model.activeHabits
        
        if let selectedCategory = selectedHabitCategory {
            return activeHabits.filter { $0.category == selectedCategory }
        }
        
        return activeHabits
    }
}

// MARK: - Habit Day Stats Card
struct HabitDayStatsCard: View {
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        let stats = model.todayHabitStats
        
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hoy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text("Progreso de hábitos")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                Spacer()
                
                // Indicador circular de progreso
                ZStack {
                    Circle()
                        .stroke(themeManager.themeColors.surface, lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: stats.percentage)
                        .stroke(
                            themeManager.currentAccentColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: stats.percentage)
                    
                    VStack(spacing: 2) {
                        Text("\(stats.completed)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(themeManager.themeColors.primary)
                        
                        Text("\(stats.total)")
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                    }
                }
            }
            
            // Barra de progreso alternativa
            HStack(spacing: 8) {
                Text("\(stats.completed) de \(stats.total) completados")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                Spacer()
                
                Text("\(Int(stats.percentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
            }
            
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.themeColors.surface)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentAccentColor)
                        .frame(width: geometry.size.width * stats.percentage, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: stats.percentage)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
                .shadow(color: themeManager.currentAccentColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Habit Category Filter
struct HabitCategoryFilter: View {
    @Binding var selectedCategory: HabitCategory?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Botón "Todos"
                CategoryFilterButton(
                    title: "Todos",
                    icon: "grid.circle.fill",
                    color: themeManager.currentAccentColor,
                    isSelected: selectedCategory == nil
                ) {
                    HapticManager.shared.lightImpact()
                    selectedCategory = nil
                }
                
                // Botones de categorías
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        HapticManager.shared.lightImpact()
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : themeManager.themeColors.surface)
            )
            .foregroundStyle(
                isSelected ? .white : themeManager.themeColors.secondary
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Habit Card
struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    private var isCompleted: Bool {
        model.isHabitCompletedToday(habitId: habit.id)
    }
    
    private var currentStreak: Int {
        model.getHabitStreak(habitId: habit.id)?.currentStreak ?? 0
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icono del hábito
                ZStack {
                    Circle()
                        .fill(habit.color.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: habit.icon)
                        .font(.title2)
                        .foregroundStyle(habit.color.color)
                }
                
                // Información del hábito
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        // Categoría
                        Label(habit.category.rawValue, systemImage: habit.category.icon)
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                        
                        if currentStreak > 0 {
                            // Streak
                            Label("\(currentStreak) días", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Estado de completado
                Button {
                    HapticManager.shared.lightImpact()
                    model.toggleHabitCompletion(habitId: habit.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? habit.color.color : themeManager.themeColors.surface)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(habit.color.color, lineWidth: 2)
                                    .opacity(isCompleted ? 0 : 1)
                            )
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(isCompleted ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isCompleted ? habit.color.color.opacity(0.3) : themeManager.themeColors.border,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isCompleted ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct HabitEmptyState: View {
    let selectedCategory: HabitCategory?
    let onAddHabit: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Icono
            ZStack {
                Circle()
                    .fill(themeManager.currentAccentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: selectedCategory?.icon ?? "heart.text.square")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.currentAccentColor)
            }
            
            // Texto
            VStack(spacing: 8) {
                Text(selectedCategory == nil ? "Sin hábitos aún" : "Sin hábitos en \(selectedCategory!.rawValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Text(selectedCategory == nil ? 
                     "Crea tu primer hábito para comenzar a construir rutinas positivas" :
                     "No tienes hábitos en esta categoría. ¡Agrega uno nuevo!")
                    .font(.body)
                    .foregroundStyle(themeManager.themeColors.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Botón
            Button(action: onAddHabit) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Agregar Hábito")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(themeManager.currentAccentColor)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
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
    HabitsView()
        .environmentObject(ChoreModel())
}