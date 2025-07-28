import Foundation
import SwiftUI

struct TaskCategory: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var color: String
    var icon: String
    
    init(name: String, color: String, icon: String) {
        self.name = name
        self.color = color
        self.icon = icon
    }
    
    var swiftUIColor: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        default: return .blue
        }
    }
    
    static let defaultCategories = [
        TaskCategory(name: "Casa", color: "green", icon: "house.fill"),
        TaskCategory(name: "Trabajo", color: "blue", icon: "briefcase.fill"),
        TaskCategory(name: "Personal", color: "purple", icon: "person.fill"),
        TaskCategory(name: "Salud", color: "red", icon: "heart.fill"),
        TaskCategory(name: "Ejercicio", color: "orange", icon: "figure.run"),
        TaskCategory(name: "Estudio", color: "indigo", icon: "book.fill"),
        TaskCategory(name: "Compras", color: "pink", icon: "cart.fill"),
        TaskCategory(name: "General", color: "teal", icon: "star.fill")
    ]
}

enum CategoryFilter: String, CaseIterable {
    case all = "Todas"
    case casa = "Casa"
    case trabajo = "Trabajo"
    case personal = "Personal"
    case salud = "Salud"
    case ejercicio = "Ejercicio"
    case estudio = "Estudio"
    case compras = "Compras"
    case general = "General"
    
    var displayName: String {
        return self.rawValue
    }
}