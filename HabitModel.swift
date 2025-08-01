import Foundation
import SwiftUI

// MARK: - Habit
struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: HabitColor
    var target: Int // Objetivo diario (ej: 8 vasos de agua, 30 min ejercicio)
    var unit: String // "vasos", "minutos", "páginas", etc.
    var category: HabitCategory
    var isActive: Bool
    var createdAt: Date
    var reminderTime: Date?
    var hasReminder: Bool
    
    init(name: String, icon: String, color: HabitColor, target: Int, unit: String, category: HabitCategory, reminderTime: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.target = target
        self.unit = unit
        self.category = category
        self.isActive = true
        self.createdAt = Date()
        self.reminderTime = reminderTime
        self.hasReminder = reminderTime != nil
    }
}

// MARK: - Habit Category
enum HabitCategory: String, CaseIterable, Codable {
    case health = "Salud"
    case fitness = "Ejercicio"
    case mindfulness = "Bienestar"
    case productivity = "Productividad"
    case learning = "Aprendizaje"
    case social = "Social"
    case creative = "Creatividad"
    case finance = "Finanzas"
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .mindfulness: return "leaf.fill"
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .creative: return "paintbrush.fill"
        case .finance: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return .red
        case .fitness: return .orange
        case .mindfulness: return .green
        case .productivity: return .blue
        case .learning: return .purple
        case .social: return .pink
        case .creative: return .yellow
        case .finance: return .mint
        }
    }
}

// MARK: - Habit Color
enum HabitColor: String, CaseIterable, Codable {
    case red = "Rojo"
    case orange = "Naranja"
    case yellow = "Amarillo"
    case green = "Verde"
    case mint = "Menta"
    case teal = "Turquesa"
    case cyan = "Cian"
    case blue = "Azul"
    case indigo = "Índigo"
    case purple = "Morado"
    case pink = "Rosa"
    case gray = "Gris"
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

// MARK: - Habit Entry
struct HabitEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let habitId: UUID
    let date: String // "yyyy-MM-dd"
    var progress: Int // Progreso actual (ej: 6 de 8 vasos)
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?
    
    init(habitId: UUID, date: String, progress: Int = 0) {
        self.id = UUID()
        self.habitId = habitId
        self.date = date
        self.progress = progress
        self.isCompleted = false
        self.completedAt = nil
        self.notes = nil
    }
    
    var progressPercentage: Double {
        guard progress > 0 else { return 0.0 }
        return min(Double(progress) / Double(1), 1.0) // Simplificado para completado/no completado
    }
}

// MARK: - Habit Streak
struct HabitStreak: Codable, Hashable {
    let habitId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: String? // "yyyy-MM-dd"
    var totalCompletions: Int
    
    init(habitId: UUID) {
        self.habitId = habitId
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletedDate = nil
        self.totalCompletions = 0
    }
    
    mutating func updateStreak(completed: Bool, date: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if completed {
            totalCompletions += 1
            
            if let lastDate = lastCompletedDate,
               let last = dateFormatter.date(from: lastDate),
               let current = dateFormatter.date(from: date) {
                
                let daysBetween = Calendar.current.dateComponents([.day], from: last, to: current).day ?? 0
                
                if daysBetween == 1 {
                    // Día consecutivo
                    currentStreak += 1
                } else if daysBetween == 0 {
                    // Mismo día (actualización)
                    // No cambiar streak
                } else {
                    // Se rompió la racha
                    currentStreak = 1
                }
            } else {
                // Primera vez o después de una pausa
                currentStreak = 1
            }
            
            lastCompletedDate = date
            longestStreak = max(longestStreak, currentStreak)
        }
    }
}

// MARK: - Preset Habits
extension Habit {
    static let presetHabits: [Habit] = [
        // Salud
        Habit(name: "Beber agua", icon: "drop.fill", color: .cyan, target: 8, unit: "vasos", category: .health),
        Habit(name: "Dormir 8 horas", icon: "moon.fill", color: .indigo, target: 8, unit: "horas", category: .health),
        Habit(name: "Tomar vitaminas", icon: "pills.fill", color: .orange, target: 1, unit: "dosis", category: .health),
        
        // Ejercicio
        Habit(name: "Caminar", icon: "figure.walk", color: .green, target: 10000, unit: "pasos", category: .fitness),
        Habit(name: "Ejercicio", icon: "figure.run", color: .red, target: 30, unit: "minutos", category: .fitness),
        Habit(name: "Estiramientos", icon: "figure.flexibility", color: .mint, target: 15, unit: "minutos", category: .fitness),
        
        // Bienestar
        Habit(name: "Meditar", icon: "brain.head.profile", color: .purple, target: 10, unit: "minutos", category: .mindfulness),
        Habit(name: "Gratitud", icon: "heart.text.square.fill", color: .pink, target: 3, unit: "cosas", category: .mindfulness),
        Habit(name: "Respiración profunda", icon: "lungs.fill", color: .teal, target: 5, unit: "minutos", category: .mindfulness),
        
        // Productividad
        Habit(name: "Revisar emails", icon: "envelope.fill", color: .blue, target: 1, unit: "vez", category: .productivity),
        Habit(name: "Planificar día", icon: "calendar", color: .orange, target: 1, unit: "vez", category: .productivity),
        Habit(name: "Limpiar escritorio", icon: "tray.fill", color: .gray, target: 1, unit: "vez", category: .productivity),
        
        // Aprendizaje
        Habit(name: "Leer", icon: "book.fill", color: .yellow, target: 30, unit: "minutos", category: .learning),
        Habit(name: "Practicar idioma", icon: "globe", color: .green, target: 20, unit: "minutos", category: .learning),
        Habit(name: "Escuchar podcast", icon: "headphones", color: .blue, target: 1, unit: "episodio", category: .learning),
        
        // Social
        Habit(name: "Llamar familia", icon: "phone.fill", color: .pink, target: 1, unit: "llamada", category: .social),
        Habit(name: "Mensaje a amigo", icon: "message.fill", color: .blue, target: 1, unit: "mensaje", category: .social),
        
        // Creatividad
        Habit(name: "Dibujar", icon: "pencil.tip.crop.circle", color: .yellow, target: 15, unit: "minutos", category: .creative),
        Habit(name: "Tocar instrumento", icon: "music.note", color: .purple, target: 30, unit: "minutos", category: .creative),
        
        // Finanzas
        Habit(name: "Revisar gastos", icon: "chart.bar.fill", color: .mint, target: 1, unit: "vez", category: .finance),
        Habit(name: "Ahorrar", icon: "banknote.fill", color: .green, target: 1, unit: "vez", category: .finance)
    ]
}