// LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme // Detecta el modo oscuro
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    // Colores que cambian según el modo
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.15) // Gris oscuro para dark mode
            : Color(red: 0.373, green: 0.129, blue: 0.192) // Guinda para light mode
    }
    
    var body: some View {
        ZStack {
            // Fondo que cambia según el modo
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                Image("logo") // Asegúrate de agregar tu logo a Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                // Textos de bienvenida
                VStack(spacing: 8) {
                    Text("Bienvenido")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Inicia sesión para continuar")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Campos de login
                VStack(spacing: 16) {
                    // Campo Email
                    TextField("Correo Electrónico", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    // Campo Password con mismo ancho
                    ZStack {
                        if showPassword {
                            TextField("Contraseña", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Contraseña", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Botón del ojo posicionado absolutamente
                        HStack {
                            Spacer()
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    
                    // Botón de login o loading
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.top, 8)
                    } else {
                        Button(action: login) {
                            Text("Ingresar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    }
                    
                    // Botón biométrico si está disponible
                    if authManager.canUseBiometrics() {
                        VStack(spacing: 12) {
                            Text("o")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                            
                            Button(action: authenticateWithBiometrics) {
                                VStack(spacing: 8) {
                                    Image(systemName: getBiometricIcon())
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(getBiometricText())
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    
                    // Error message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            // Intentar autenticación biométrica automática si hay sesión guardada
            if authManager.canUseBiometrics() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authManager.authenticateWithBiometrics()
                }
            }
        }
    }
    
    // MARK: - Funciones privadas
    
    private func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedEmail.isEmpty && !trimmedPassword.isEmpty else { return }
        guard isValidEmail(trimmedEmail) else {
            authManager.errorMessage = "Por favor, ingresa un correo válido"
            return
        }
        
        authManager.login(email: trimmedEmail, password: trimmedPassword)
    }
    
    private func authenticateWithBiometrics() {
        authManager.authenticateWithBiometrics()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func getBiometricIcon() -> String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                return "lock.shield"
            }
        }
        return "lock.shield"
    }
    
    private func getBiometricText() -> String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "Usar Face ID"
            case .touchID:
                return "Usar Touch ID"
            default:
                return "Usar Biometría"
            }
        }
        return "Usar Biometría"
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
