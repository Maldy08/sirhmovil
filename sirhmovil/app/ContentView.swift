// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSplash = false
                
                if authManager.hasStoredSession() && authManager.canUseBiometrics() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        authManager.authenticateWithBiometrics()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if authManager.isAuthenticated {
            EnhancedRecibosView() // ¡NUEVA PANTALLA!
                .environmentObject(authManager)
        } else {
            LoginView()
                .environmentObject(authManager)
        }
    }
}
