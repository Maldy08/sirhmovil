// AppDelegate.swift
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    // MARK: - APNS Callbacks
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNS Token recibido en AppDelegate")
        NotificationManager.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS falló en AppDelegate: \(error.localizedDescription)")
        NotificationManager.shared.didFailToRegisterForRemoteNotifications(withError: error)
    }
}
