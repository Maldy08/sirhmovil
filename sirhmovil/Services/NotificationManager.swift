// NotificationManager.swift
import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import Combine

class NotificationManager: NSObject, ObservableObject {
    @Published var fcmToken: String?
    @Published var hasPermission = false
    
    static let shared = NotificationManager()
    
    // NUEVO: Referencia al AuthManager compartido
    weak var authManager: AuthManager?
    
    // MARK: - Combine para manejo de suscripciones
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        requestNotificationPermission()
        setupFirebaseMessaging() // ✅ Habilitado
    }
    
    // MARK: - Permisos de notificaciones
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                
                if granted {
                    print("✅ Permisos de notificación concedidos")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ Permisos de notificación denegados")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Manejo de token APNS
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        print("✅ Token APNS recibido")
        
        // Configurar token APNS en Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Ahora solicitar token FCM
        requestFCMToken()
    }
    
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("❌ Error registrando APNS: \(error.localizedDescription)")
        
        // En simulador o desarrollo, aún podemos obtener token FCM
        print("ℹ️ Intentando obtener token FCM sin APNS (modo desarrollo)")
        requestFCMToken()
    }
    
    private func requestFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ Error obteniendo token FCM: \(error.localizedDescription)")
            } else if let token = token {
                print("🔑 Token FCM obtenido exitosamente: \(String(token.prefix(20)))...")
                DispatchQueue.main.async {
                    self?.fcmToken = token
                }
                self?.sendTokenToBackendIfNeeded(token)
            }
        }
    }
    
    // MARK: - Verificar estado de permisos
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Firebase Messaging (ahora habilitado)
    private func setupFirebaseMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        print("🔥 Firebase Messaging configurado")
        
        // No solicitamos token aquí, lo haremos después del registro APNS
        // o en caso de error APNS (simulador/desarrollo)
    }
    
    // MARK: - Enviar token al backend
    func sendTokenToBackendIfNeeded(_ token: String) {
        // Verificar si hay un token de autenticación disponible
        let keychain = KeychainHelper()
        if let authToken = keychain.getToken() {
            let apiService = APIService()
            
            apiService.sendFcmToken(token, authToken: authToken)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Error enviando FCM token al backend: \(error)")
                        }
                    },
                    receiveValue: {
                        print("✅ FCM token enviado al backend exitosamente")
                    }
                )
                .store(in: &cancellables)
        } else {
            print("ℹ️ No hay token de autenticación, FCM token se enviará después del login")
        }
    }
    
    // MARK: - Manejar navegación desde notificaciones
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("🔔 Notificación tocada con datos: \(userInfo)")
        
        // Extraer datos de la notificación (como en tu Flutter)
        guard let empleadoId = userInfo["empleadoId"] as? String,
              let periodo = userInfo["periodo"] as? String,
              let tipo = userInfo["tipo"] as? String,
              let empleadoInt = Int(empleadoId),
              let periodoInt = Int(periodo),
              let tipoInt = Int(tipo) else {
            print("❌ Datos de notificación inválidos")
            return
        }
        
        print("➡️ Navegar a PDF: empleado=\(empleadoInt), periodo=\(periodoInt), tipo=\(tipoInt)")
        
        // NUEVO: Verificar si el usuario está autenticado usando el AuthManager compartido
        DispatchQueue.main.async {
            guard let authManager = self.authManager else {
                print("❌ AuthManager no está disponible - navegación directa")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToPDF"),
                    object: ["empleado": empleadoInt, "periodo": periodoInt, "tipo": tipoInt]
                )
                return
            }
            
            print("🚨 DEBUG: isAuthenticated = \(authManager.isAuthenticated)")
            print("🚨 DEBUG: hasStoredSession = \(authManager.hasStoredSession())")
            
            if authManager.isAuthenticated {
                // Usuario ya autenticado - navegar directamente
                print("✅ Usuario autenticado - navegación directa")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToPDF"),
                    object: ["empleado": empleadoInt, "periodo": periodoInt, "tipo": tipoInt]
                )
            } else if authManager.hasStoredSession() {
                // Usuario tiene sesión pero no está autenticado - almacenar navegación pendiente
                print("⏳ Usuario no autenticado - almacenando navegación pendiente")
                authManager.setPendingNavigation(
                    empleado: empleadoInt,
                    periodo: periodoInt,
                    tipo: tipoInt
                )
                
                // La navegación se ejecutará automáticamente después de la autenticación biométrica
            } else {
                // No hay sesión guardada - navegar solo después del login manual
                print("❌ No hay sesión guardada - navegación después del login")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToPDF"),
                    object: ["empleado": empleadoInt, "periodo": periodoInt, "tipo": tipoInt]
                )
            }
        }
    }
    
    // MARK: - Forzar actualización de token
    func refreshFCMToken() {
        Messaging.messaging().deleteToken { [weak self] error in
            if let error = error {
                print("❌ Error eliminando token FCM: \(error)")
            } else {
                print("🔄 Token FCM eliminado, obteniendo nuevo...")
                Messaging.messaging().token { token, error in
                    if let token = token {
                        DispatchQueue.main.async {
                            self?.fcmToken = token
                        }
                        self?.sendTokenToBackendIfNeeded(token)
                    }
                }
            }
        }
    }
}

// MARK: - Firebase Messaging Delegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 Token FCM actualizado: \(String(describing: fcmToken))")
        
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
        }
        
        // Enviar token actualizado al backend
        if let token = fcmToken {
            sendTokenToBackendIfNeeded(token)
        }
    }
}

// MARK: - User Notification Center Delegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Cuando la app está en primer plano
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar banner, sonido y badge incluso cuando la app está activa
        completionHandler([.banner, .sound, .badge])
    }
    
    // Cuando el usuario toca la notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
}

// MARK: - Helpers para mostrar notificaciones en la app
extension NotificationManager {
    func showInAppNotification(title: String, body: String, data: [String: Any] = [:]) {
        // Crear notificación local para mostrar en la app
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.userInfo = data
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error mostrando notificación: \(error)")
            }
        }
    }
}
