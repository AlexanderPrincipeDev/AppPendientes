import SwiftUI

struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var logoScale = 0.5
    @State private var logoOpacity = 0.0
    @State private var titleOffset = 50.0
    @State private var titleOpacity = 0.0
    @State private var progressValue = 0.0
    
    var onLoadingComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Fondo gradiente
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo de la aplicación (ícono de lista de tareas)
                VStack(spacing: 20) {
                    ZStack {
                        // Círculo de fondo
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        // Ícono de lista de tareas
                        VStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                HStack(spacing: 8) {
                                    // Checkbox
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                    
                                    // Línea de texto
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: 30, height: 4)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                
                // Título de la aplicación
                VStack(spacing: 8) {
                    Text("Lista Pendientes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Organiza tu día, logra tus metas")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                
                Spacer()
                
                // Barra de progreso
                VStack(spacing: 16) {
                    // Indicador de carga
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Cargando...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(isLoading ? 1 : 0)
                
                Spacer().frame(height: 80)
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        // Animación del logo
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animación del título
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Simular tiempo de carga
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
            
            // Completar la carga después de la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onLoadingComplete()
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView {
            print("Loading complete")
        }
    }
}