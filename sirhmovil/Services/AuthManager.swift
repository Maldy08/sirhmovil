// AuthManager.swift
import Foundation
import Combine
import Security
import LocalAuthentication

class AuthManager: ObservableObject {
    // Estados publicados para la UI
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: Empleado?
    
    // Servicios
    private let apiService = APIService()
    private let keychain = KeychainHelper()
    private let localAuth = LAContext()
    
    // Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Token actual
    var token: String? {
        return keychain.getToken()
    }
    
    init() {
        loadSessionFromStorage()
    }
    
    // MARK: - Login con email/password
    func login(email: String, password: String, fcmToken: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        apiService.login(email: email, password: password, fcmToken: fcmToken)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleLoginSuccess(response: response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleLoginSuccess(response: LoginResponse) {
        // Guardar token en Keychain (seguro)
        keychain.saveToken(response.token)
        
        // Guardar usuario en UserDefaults
        if let userData = try? JSONEncoder().encode(response.empleado) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        // Actualizar estado
        currentUser = response.empleado
        isAuthenticated = true
        
        // Enviar token FCM al backend si está disponible
        sendFcmTokenToBackend()
        
        print("✅ Login exitoso para: \(response.empleado.nombreCompleto)")
    }
    
    // MARK: - Enviar token FCM al backend
    private func sendFcmTokenToBackend() {
        guard let authToken = token else { return }
        
        // Obtener token FCM del NotificationManager
        if let fcmToken = NotificationManager.shared.fcmToken {
            apiService.sendFcmToken(fcmToken, authToken: authToken)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Error enviando FCM token: \(error)")
                        }
                    },
                    receiveValue: {
                        print("✅ FCM token enviado al backend después del login")
                    }
                )
                .store(in: &cancellables)
        } else {
            print("ℹ️ FCM token no disponible aún, se enviará cuando esté listo")
        }
    }
    
    // MARK: - Autenticación Biométrica
    func authenticateWithBiometrics() {
        guard hasStoredSession() else {
            print("❌ No hay sesión guardada para autenticación biométrica")
            return
        }
        
        let reason = "Por favor, autentícate para acceder a la app"
        
        localAuth.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Autenticación biométrica exitosa")
                    self?.unlockSession()
                } else {
                    if let error = error {
                        print("❌ Autenticación biométrica falló: \(error.localizedDescription)")
                        // Podrías mostrar un error específico aquí si lo deseas
                    }
                }
            }
        }
    }
    
    // MARK: - Verificar disponibilidad biométrica
    func canUseBiometrics() -> Bool {
        var error: NSError?
        let canEvaluate = localAuth.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let hasSession = hasStoredSession()
        
        if let error = error {
            print("ℹ️ Biometría no disponible: \(error.localizedDescription)")
        }
        
        return canEvaluate && hasSession
    }
    
    // MARK: - Gestión de sesiones
    
    /// Carga la sesión desde almacenamiento (sin autenticar automáticamente)
    private func loadSessionFromStorage() {
        if let token = token, !token.isEmpty {
            // Recuperar usuario guardado
            if let userData = UserDefaults.standard.data(forKey: "current_user"),
               let user = try? JSONDecoder().decode(Empleado.self, from: userData) {
                currentUser = user
                print("ℹ️ Sesión cargada para: \(user.nombreCompleto)")
            }
        }
    }
    
    /// Desbloquea la sesión después de autenticación biométrica exitosa
    func unlockSession() {
        if token != nil && currentUser != nil {
            isAuthenticated = true
            print("🔓 Sesión desbloqueada")
        }
    }
    
    /// Verifica si hay una sesión guardada (token + usuario)
    func hasStoredSession() -> Bool {
        return token != nil && currentUser != nil
    }
    
    // MARK: - Logout
    func logout() {
        keychain.deleteToken()
        UserDefaults.standard.removeObject(forKey: "current_user")
        
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        
        print("👋 Sesión cerrada")
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    private let tokenKey = "jwt_token"
    
    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Eliminar token anterior si existe
        SecItemDelete(query as CFDictionary)
        
        // Agregar nuevo token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Token guardado en Keychain")
        } else {
            print("❌ Error guardando token en Keychain: \(status)")
        }
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ Token eliminado del Keychain")
        } else {
            print("ℹ️ Token no encontrado en Keychain o ya eliminado")
        }
    }
}
