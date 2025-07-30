import SwiftUI

struct WelcomeView: View {
    @State private var userName = ""
    @State private var showingNameInput = true
    @FocusState private var isTextFieldFocused: Bool
    
    let onComplete: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Welcome Icon
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .padding(.bottom, 20)
                    
                    // Welcome Title
                    VStack(spacing: 12) {
                        Text("¡Bienvenido a")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Lista Pendientes!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    // Description
                    Text("Para hacer tu experiencia más personal, nos gustaría conocerte mejor")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Name Input Section
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("¿Cómo te llamas?")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            // Custom TextField with modern design
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .stroke(isTextFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                                        .frame(height: 56)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.blue.opacity(0.7))
                                        
                                        TextField("Tu nombre aquí...", text: $userName)
                                            .font(.body)
                                            .focused($isTextFieldFocused)
                                            .submitLabel(.done)
                                            .autocapitalization(.words)
                                            .disableAutocorrection(true)
                                            .onSubmit {
                                                if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    saveUserName()
                                                }
                                            }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                if isTextFieldFocused && userName.isEmpty {
                                    Text("Puedes usar tu nombre real o un apodo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 4)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Continue Button with improved design
                        Button(action: {
                            saveUserName()
                        }) {
                            HStack(spacing: 8) {
                                Text("Continuar")
                                    .fontWeight(.semibold)
                                    .font(.body)
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                        : [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? .clear
                                    : .blue.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.98 : 1.0)
                        }
                        .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: userName.isEmpty)
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    
                    // Skip option
                    Button("Continuar sin nombre") {
                        onComplete("")
                    }
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func saveUserName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        onComplete(trimmedName)
    }
}

#Preview {
    WelcomeView { name in
        print("Usuario ingresó: \(name)")
    }
}
