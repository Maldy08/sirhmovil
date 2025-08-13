// SplashView.swift
import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) var colorScheme // Detecta el modo oscuro
    @State private var isLoading = true
    
    // Colores que cambian según el modo
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.15) // Gris oscuro para dark mode
            : Color(red: 0.373, green: 0.129, blue: 0.192) // Guinda para light mode
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo desde Assets
                Image("logo") // Tu logo aquí
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 150)
                
                // Nombre de la app
                Text("Sistema RRHH")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                // Indicador de carga
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            // Simular tiempo de carga
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
