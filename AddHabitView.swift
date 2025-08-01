import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: ChoreModel
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var habitName = ""
    @State private var selectedCategory: HabitCategory = .health
    @State private var selectedColor: HabitColor = .blue
    @State private var selectedIcon = "heart.fill"
    @State private var target = 1
    @State private var unit = "vez"
    @State private var hasReminder = false
    @State private var reminderTime = Date()
    @State private var showingPresetHabits = false
    
    private let commonUnits = ["vez", "veces", "minutos", "horas", "vasos", "páginas", "kilómetros", "repeticiones"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preset Habits Section
                    PresetHabitsSection {
                        showingPresetHabits = true
                    }
                    
                    // Custom Habit Form
                    VStack(spacing: 20) {
                        HabitSectionHeader(title: "Hábito Personalizado", subtitle: "Crea tu propio hábito único")
                        
                        // Nombre del hábito
                        HabitNameField(name: $habitName)
                        
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
                    }
                    
                    // Preview del hábito
                    if !habitName.isEmpty {
                        HabitPreviewCard(
                            name: habitName,
                            category: selectedCategory,
                            color: selectedColor,
                            icon: selectedIcon,
                            target: target,
                            unit: unit
                        )
                    }
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Nuevo Hábito")
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
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentAccentColor)
                    .disabled(habitName.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingPresetHabits) {
            PresetHabitsView { selectedHabit in
                // Cargar datos del hábito preestablecido
                habitName = selectedHabit.name
                selectedCategory = selectedHabit.category
                selectedColor = selectedHabit.color
                selectedIcon = selectedHabit.icon
                target = selectedHabit.target
                unit = selectedHabit.unit
                showingPresetHabits = false
            }
        }
        .themedAccent()
    }
    
    private func saveHabit() {
        let newHabit = Habit(
            name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor,
            target: target,
            unit: unit,
            category: selectedCategory,
            reminderTime: hasReminder ? reminderTime : nil
        )
        
        model.addHabit(newHabit)
        HapticManager.shared.successImpact()
        dismiss()
    }
}

// MARK: - Preset Habits Section
struct PresetHabitsSection: View {
    let onShowPresets: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hábitos Populares")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text("Comienza con plantillas predefinidas")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                Spacer()
            }
            
            Button(action: onShowPresets) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(themeManager.currentAccentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Explorar Plantillas")
                            .font(.headline)
                            .foregroundStyle(themeManager.themeColors.primary)
                        
                        Text("Más de 20 hábitos listos para usar")
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.themeColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Section Header
struct HabitSectionHeader: View {
    let title: String
    let subtitle: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.themeColors.primary)
                
                Spacer()
            }
            
            HStack {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                Spacer()
            }
        }
    }
}

// MARK: - Habit Name Field
struct HabitNameField: View {
    @Binding var name: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre del Hábito")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            TextField("Ej: Beber agua, Meditar, Ejercicio...", text: $name)
                .textFieldStyle(.plain)
                .font(.body)
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

// MARK: - Habit Category Selector
struct HabitCategorySelector: View {
    @Binding var selectedCategory: HabitCategory
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categoría")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    Button {
                        HapticManager.shared.lightImpact()
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory == category ? category.color.opacity(0.2) : themeManager.themeColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedCategory == category ? category.color : themeManager.themeColors.border,
                                            lineWidth: selectedCategory == category ? 2 : 1
                                        )
                                )
                        )
                        .foregroundStyle(
                            selectedCategory == category ? category.color : themeManager.themeColors.secondary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Habit Appearance Selector
struct HabitAppearanceSelector: View {
    @Binding var selectedColor: HabitColor
    @Binding var selectedIcon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    private let availableIcons = [
        "heart.fill", "drop.fill", "leaf.fill", "figure.run", "book.fill",
        "brain.head.profile", "phone.fill", "music.note", "paintbrush.fill",
        "dollarsign.circle.fill", "house.fill", "car.fill", "airplane",
        "camera.fill", "gamecontroller.fill", "tv.fill", "headphones",
        "message.fill", "envelope.fill", "calendar"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apariencia")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            // Selector de colores
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(HabitColor.allCases, id: \.self) { color in
                        Button {
                            HapticManager.shared.lightImpact()
                            selectedColor = color
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 40, height: 40)
                                
                                if selectedColor == color {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Selector de iconos
            VStack(alignment: .leading, spacing: 8) {
                Text("Icono")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.themeColors.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            HapticManager.shared.lightImpact()
                            selectedIcon = icon
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : themeManager.themeColors.surface)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedIcon == icon ? selectedColor.color : themeManager.themeColors.border,
                                                lineWidth: selectedIcon == icon ? 2 : 1
                                            )
                                    )
                                
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(selectedIcon == icon ? selectedColor.color : themeManager.themeColors.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Habit Target Selector
struct HabitTargetSelector: View {
    @Binding var target: Int
    @Binding var unit: String
    let availableUnits: [String]
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingUnitPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objetivo Diario")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            HStack(spacing: 12) {
                // Selector de cantidad
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cantidad")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    HStack {
                        Button {
                            if target > 1 {
                                target -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(themeManager.currentAccentColor)
                        }
                        .disabled(target <= 1)
                        
                        Text("\(target)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(themeManager.themeColors.primary)
                            .frame(minWidth: 50)
                        
                        Button {
                            target += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(themeManager.currentAccentColor)
                        }
                    }
                }
                
                Spacer()
                
                // Selector de unidad
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unidad")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                    
                    Button {
                        showingUnitPicker = true
                    } label: {
                        HStack {
                            Text(unit)
                                .foregroundStyle(themeManager.themeColors.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(themeManager.themeColors.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.themeColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .confirmationDialog("Seleccionar Unidad", isPresented: $showingUnitPicker) {
            ForEach(availableUnits, id: \.self) { unitOption in
                Button(unitOption) {
                    unit = unitOption
                }
            }
        }
    }
}

// MARK: - Habit Reminder Section
struct HabitReminderSection: View {
    @Binding var hasReminder: Bool
    @Binding var reminderTime: Date
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recordatorio")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recordatorio diario")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    Text("Recibe una notificación para no olvidarlo")
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $hasReminder)
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
            
            if hasReminder {
                DatePicker(
                    "Hora del recordatorio",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 120)
                .clipped()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 0.8))
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasReminder)
    }
}

// MARK: - Habit Preview Card
struct HabitPreviewCard: View {
    let name: String
    let category: HabitCategory
    let color: HabitColor
    let icon: String
    let target: Int
    let unit: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vista Previa")
                .font(.headline)
                .foregroundStyle(themeManager.themeColors.primary)
            
            HStack(spacing: 16) {
                // Icono
                ZStack {
                    Circle()
                        .fill(color.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color.color)
                }
                
                // Información
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary)
                    
                    HStack(spacing: 12) {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                        
                        Text("Meta: \(target) \(unit)")
                            .font(.caption)
                            .foregroundStyle(color.color)
                    }
                }
                
                Spacer()
                
                // Checkbox preview
                Circle()
                    .stroke(color.color, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    AddHabitView()
        .environmentObject(ChoreModel())
}
