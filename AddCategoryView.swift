import SwiftUI

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: ChoreModel
    
    @State private var categoryName = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = Color.blue
    
    private let availableIcons = [
        "folder", "house", "briefcase", "person", "heart", "gamecontroller",
        "book", "car", "cart", "dumbbell", "music.note", "camera",
        "leaf", "star", "globe", "paintbrush", "wrench", "lightbulb"
    ]
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        .teal, .indigo, .mint, .yellow, .cyan, .brown
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre de la categoría")
                        .font(.headline)
                    
                    TextField("Ej: Ejercicio, Estudios, Cocina...", text: $categoryName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icono")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedIcon == icon ? .white : selectedColor)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? selectedColor : Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Preview
                VStack(spacing: 8) {
                    Text("Vista previa")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 16))
                            .foregroundStyle(selectedColor)
                        Text(categoryName.isEmpty ? "Nombre de categoría" : categoryName)
                            .font(.body)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .navigationTitle("Nueva Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        // Check if category name already exists
        let existingCategory = model.categories.first { $0.name.lowercased() == trimmedName.lowercased() }
        
        if existingCategory == nil {
            // Convert Color to string representation
            let colorString = colorToString(selectedColor)
            model.addCategory(name: trimmedName, color: colorString, icon: selectedIcon)
        }
        
        dismiss()
    }
    
    private func colorToString(_ color: Color) -> String {
        // Map SwiftUI colors to string representations
        switch color {
        case .blue: return "blue"
        case .green: return "green"
        case .orange: return "orange"
        case .red: return "red"
        case .purple: return "purple"
        case .pink: return "pink"
        case .yellow: return "yellow"
        case .indigo: return "indigo"
        case .teal: return "teal"
        case .mint: return "mint"
        case .cyan: return "cyan"
        case .brown: return "brown"
        default: return "blue"
        }
    }
}
