import SwiftUI

struct PresetHabitsView: View {
    let onSelectHabit: (Habit) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedCategory: HabitCategory? = nil
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barra de búsqueda
                SearchBar(text: $searchText)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Filtros por categoría
                CategoryFilterScrollView(selectedCategory: $selectedCategory)
                    .padding(.bottom, 16)
                
                // Lista de hábitos
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPresetHabits) { habit in
                            PresetHabitCard(habit: habit) {
                                HapticManager.shared.successImpact()
                                onSelectHabit(habit)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(themeManager.themeColors.background)
            .navigationTitle("Hábitos Populares")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(themeManager.themeColors.secondary)
                }
            }
        }
        .themedAccent()
    }
    
    private var filteredPresetHabits: [Habit] {
        var habits = Habit.presetHabits
        
        // Filtrar por categoría
        if let selectedCategory = selectedCategory {
            habits = habits.filter { $0.category == selectedCategory }
        }
        
        // Filtrar por búsqueda
        if !searchText.isEmpty {
            habits = habits.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return habits
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeManager.themeColors.secondary)
            
            TextField("Buscar hábitos...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.themeColors.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeManager.themeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeManager.themeColors.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Category Filter Scroll View
struct CategoryFilterScrollView: View {
    @Binding var selectedCategory: HabitCategory?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Botón "Todos"
                FilterChip(
                    title: "Todos",
                    icon: "grid.circle.fill",
                    color: themeManager.currentAccentColor,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // Botones de categorías
                ForEach(HabitCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct FilterChip: View {
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
                Capsule()
                    .fill(isSelected ? color : themeManager.themeColors.surface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color : themeManager.themeColors.border, lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? .white : themeManager.themeColors.secondary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Habit Card
struct PresetHabitCard: View {
    let habit: Habit
    let onSelect: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icono del hábito
                ZStack {
                    Circle()
                        .fill(habit.color.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(habit.color.color)
                }
                
                // Información del hábito
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // Categoría
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
                        
                        // Meta
                        Text("Meta: \(habit.target) \(habit.unit)")
                            .font(.caption)
                            .foregroundStyle(themeManager.themeColors.secondary)
                    }
                    
                    // Descripción motivacional
                    Text(habitDescription(for: habit))
                        .font(.caption)
                        .foregroundStyle(themeManager.themeColors.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Botón de acción
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeManager.currentAccentColor)
                    
                    Text("Agregar")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.currentAccentColor)
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
                    .shadow(color: habit.color.color.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func habitDescription(for habit: Habit) -> String {
        switch habit.name {
        case "Beber agua":
            return "Mantente hidratado y mejora tu energía"
        case "Dormir 8 horas":
            return "Recupera tu cuerpo y mente cada noche"
        case "Tomar vitaminas":
            return "Cuida tu salud con suplementos diarios"
        case "Caminar":
            return "Actívate con pasos diarios saludables"
        case "Ejercicio":
            return "Fortalece tu cuerpo y mejora tu estado físico"
        case "Estiramientos":
            return "Mantén la flexibilidad y reduce tensiones"
        case "Meditar":
            return "Encuentra paz interior y reduce el estrés"
        case "Gratitud":
            return "Aprecia lo bueno en tu vida cada día"
        case "Respiración profunda":
            return "Calma tu mente con ejercicios de respiración"
        case "Revisar emails":
            return "Mantén tu bandeja de entrada organizada"
        case "Planificar día":
            return "Organiza tus prioridades cada mañana"
        case "Limpiar escritorio":
            return "Un espacio ordenado mejora la productividad"
        case "Leer":
            return "Expande tu conocimiento con lectura diaria"
        case "Practicar idioma":
            return "Mejora tus habilidades lingüísticas"
        case "Escuchar podcast":
            return "Aprende algo nuevo mientras haces otras tareas"
        case "Llamar familia":
            return "Mantén vínculos fuertes con tus seres queridos"
        case "Mensaje a amigo":
            return "Cultiva amistades con contacto regular"
        case "Dibujar":
            return "Expresa tu creatividad a través del arte"
        case "Tocar instrumento":
            return "Desarrolla habilidades musicales"
        case "Revisar gastos":
            return "Mantén control sobre tus finanzas"
        case "Ahorrar":
            return "Construye un futuro financiero sólido"
        default:
            return "Desarrolla este hábito positivo en tu rutina"
        }
    }
}

#Preview {
    PresetHabitsView { habit in
        print("Selected habit: \(habit.name)")
    }
}