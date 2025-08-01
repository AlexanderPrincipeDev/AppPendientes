import SwiftUI

struct EditHabitView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var habitName: String
    @State private var selectedCategory: HabitCategory
    @State private var selectedColor: HabitColor
    @State private var selectedIcon: String
    @State private var target: Int
    @State private var unit: String
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    @State private var isActive: Bool
    
    private let commonUnits = ["vez", "veces", "minutos", "horas", "vasos", "páginas", "kilómetros", "repeticiones"]
    
    init(habit: Habit) {
        self.habit = habit
        _habitName = State(initialValue: habit.name)
        _selectedCategory = State(initialValue: habit.category)
        _selectedColor = State(initialValue: habit.color)
        _selectedIcon = State(initialValue: habit.icon)
        _target = State(initialValue: habit.target)
        _unit = State(initialValue: habit.unit)
        _hasReminder = State(initialValue: habit.hasReminder)
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())
        _isActive = State(initialValue: habit.isActive)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Nombre del hábito
                    HabitNameField(name: $habitName)
                    
                    // Estado activo/inactivo
                    HabitActiveToggle(isActive: $isActive)
                    
                    // Categoría
                    HabitCategorySelector(selectedCategory: $selectedCategory)
                    
                    // Color e Icono
                    HabitAppearanceSelector(
                        selectedColor: $selectedColor,
                        selectedIcon: $selectedIcon
                    )
                    
                    // Objetivo y Unidad
                    HabitTargetSelector(
                        target: $target,
                        unit: $unit,
                        availableUnits: commonUnits
                    )
                    
                    // Recordatorio
                    HabitReminderSection(
                        hasReminder: $hasReminder,
                        reminderTime: $reminderTime
                    )
                    
                    // Preview del hábito
                    HabitPreviewCard(
                        name: habitName,
                        category: selectedCategory,
                        color: selectedColor,
                        icon: selectedIcon,
                        target: target,
                        unit: unit
                    )
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Editar Hábito")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
                    .disabled(habitName.isEmpty)
                }
            }
        }
        .themedAccent()
    }
    
    private func saveChanges() {
        guard let index = model.habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        // Cancelar notificación anterior si existe
        if model.habits[index].hasReminder {
            NotificationService.shared.cancelNotification(for: habit.id)
        }
        
        // Actualizar hábito
        model.habits[index].name = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        model.habits[index].category = selectedCategory
        model.habits[index].color = selectedColor
        model.habits[index].icon = selectedIcon
        model.habits[index].target = target
        model.habits[index].unit = unit
        model.habits[index].hasReminder = hasReminder
        model.habits[index].reminderTime = hasReminder ? reminderTime : nil
        model.habits[index].isActive = isActive
        
        // Programar nueva notificación si es necesario
        if hasReminder {
            NotificationService.shared.scheduleHabitReminder(habit: model.habits[index], at: reminderTime)
        }
        
        model.saveHabits()
        HapticManager.shared.successImpact()
        dismiss()
    }
}

// MARK: - Habit Active Toggle
struct HabitActiveToggle: View {
    @Binding var isActive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estado")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hábito activo")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text("Los hábitos inactivos no aparecen en el seguimiento diario")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isActive)
                    .labelsHidden()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.themeColors.border, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    EditHabitView(habit: Habit.presetHabits[0])
        .environmentObject(ChoreModel())
}