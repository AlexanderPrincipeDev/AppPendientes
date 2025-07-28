import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    var onAdd: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("¿Qué tarea quieres agregar?", text: $title)
                        .focused($isTitleFocused)
                }
            }
            .navigationTitle("Nueva Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
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
        .onAppear {
            isTitleFocused = true
        }
    }
}
