// ConnectivityManager.swift
import Foundation
import Network
import Combine
import SwiftUI

class ConnectivityManager: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    static let shared = ConnectivityManager()
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                // Determinar tipo de conexión
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
                
                // Logs para debugging
                if let isConnected = self?.isConnected {
                    if isConnected && !wasConnected {
                        print("🌐 Conexión restaurada (\(self?.connectionTypeText ?? "unknown"))")
                    } else if !isConnected && wasConnected {
                        print("❌ Conexión perdida")
                    }
                }
            }
        }
        
        monitor.start(queue: queue)
        print("🔍 ConnectivityManager iniciado")
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Helpers
    
    var connectionTypeText: String {
        guard isConnected else { return "Sin conexión" }
        
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Datos móviles"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Conectado"
        }
    }
    
    var connectionIcon: String {
        guard isConnected else { return "wifi.slash" }
        
        switch connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .wiredEthernet:
            return "cable.connector"
        default:
            return "network"
        }
    }
    
    // MARK: - Funciones públicas
    
    func checkConnection() -> Bool {
        return isConnected
    }
    
    func forceRefresh() {
        // Reinicia el monitor
        monitor.cancel()
        startMonitoring()
    }
}

// MARK: - Vista del Banner de Conectividad
struct ConnectivityBanner: View {
    @StateObject private var connectivityManager = ConnectivityManager.shared
    @State private var showBanner = false
    
    var body: some View {
        if !connectivityManager.isConnected {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sin conexión a Internet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Verifica tu conexión WiFi o datos móviles")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button("Reintentar") {
                    connectivityManager.forceRefresh()
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red)
            .opacity(showBanner ? 1 : 0)
            .offset(y: showBanner ? 0 : -50)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBanner = true
                }
            }
            .onDisappear {
                showBanner = false
            }
        }
    }
}

// MARK: - Layout Principal con Conectividad
struct MainLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ConnectivityBanner()
            content
        }
    }
}

// MARK: - Vista de Estado de Conexión (para debugging)
struct ConnectionStatusView: View {
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: connectivityManager.connectionIcon)
                .foregroundColor(connectivityManager.isConnected ? .green : .red)
            
            Text(connectivityManager.connectionTypeText)
                .font(.caption)
                .foregroundColor(connectivityManager.isConnected ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Modifier para requests con conectividad
extension View {
    func requiresConnection() -> some View {
        modifier(ConnectivityModifier())
    }
}

struct ConnectivityModifier: ViewModifier {
    @StateObject private var connectivityManager = ConnectivityManager.shared
    @State private var showOfflineAlert = false
    
    func body(content: Content) -> some View {
        content
            .alert("Sin Conexión", isPresented: $showOfflineAlert) {
                Button("OK") { }
                Button("Configuración") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Esta acción requiere conexión a Internet. Verifica tu conexión y vuelve a intentar.")
            }
            .onChange(of: connectivityManager.isConnected) { isConnected in
                if !isConnected {
                    showOfflineAlert = true
                }
            }
    }
}
