import SwiftUI

struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var logoScale = 0.5
    @State private var logoOpacity = 0.0
    @State private var titleOffset = 30.0
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var progressOpacity = 0.0
    @State private var waveAnimation = false
    
    var onLoadingComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Fondo gradiente
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo de la aplicación
                VStack(spacing: 24) {
                    ZStack {
                        // Círculo de fondo con efecto de resplandor
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .blue.opacity(0.15),
                                        .blue.opacity(0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(waveAnimation ? 1.1 : 1.0)
                        
                        // Contenedor principal del logo
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
                        
                        // Ícono de lista de tareas moderno
                        VStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { index in
                                HStack(spacing: 8) {
                                    // Checkbox moderno con degradado
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    // Línea de texto con estilo moderno
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [.primary.opacity(0.7), .primary.opacity(0.5)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 32, height: 3)
                                        .opacity(index == 0 ? 1.0 : (index == 1 ? 0.7 : 0.4))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 22)
                                .scaleEffect(index == 0 ? 1.0 : (index == 1 ? 0.9 : 0.8))
                            }
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                
                // Título y descripción de la aplicación
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Lista Pendientes")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Organiza tu día, logra tus metas")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    
                    Text("Preparando tu experiencia personalizada")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(subtitleOpacity)
                }
                
                Spacer()
                
                // Indicador de carga moderno
                VStack(spacing: 20) {
                    // Puntos de carga animados
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 12, height: 12)
                                .scaleEffect(waveAnimation ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: waveAnimation
                                )
                        }
                    }
                    
                    Text("Cargando...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .opacity(progressOpacity)
                
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        // Animación del logo
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animación del título con retraso
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Animación de la descripción
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            subtitleOpacity = 1.0
        }
        
        // Animación del indicador de progreso
        withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
            progressOpacity = 1.0
        }
        
        // Iniciar animación de onda para los puntos de carga y resplandor de fondo
        withAnimation(.easeInOut(duration: 0.8).delay(1.0)) {
            waveAnimation = true
        }
        
        // Completar el proceso de carga
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                logoOpacity = 0.0
                titleOpacity = 0.0
                subtitleOpacity = 0.0
                progressOpacity = 0.0
            }
            
            // Completar la carga después de la animación de desvanecimiento
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onLoadingComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Loading complete")
    }
}
