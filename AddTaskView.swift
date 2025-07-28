import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @FocusState private var isFocused: Bool
    var onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("¿Qué tarea quieres añadir?", text: $title)
                        .focused($isFocused)
                        .autocapitalization(.sentences)
                }
                .listRowBackground(Color(.systemGroupedBackground))
            }
            .navigationTitle("Nueva Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onAdd(trimmed)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(180)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isFocused = true
        }
    }
}
