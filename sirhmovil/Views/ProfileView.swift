// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Colores que cambian según el modo
    private var primaryColor: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.15) // Gris oscuro para dark mode
            : Color(red: 0.373, green: 0.129, blue: 0.192) // Guinda para light mode
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let user = authManager.currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header con avatar
                            profileHeader(user: user)
                            
                            // Información personal
                            personalInfoSection(user: user)
                            
                            // Información laboral
                            workInfoSection(user: user)
                            
                            // Configuraciones de la app
                            appSettingsSection()
                            
                            Spacer(minLength: 50)
                        }
                        .padding()
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subvistas
    
    private func profileHeader(user: Empleado) -> some View {
        VStack(spacing: 16) {
            // Avatar con iniciales
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(user.iniciales)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(primaryColor)
            }
            
            // Información básica
            VStack(spacing: 4) {
                Text(user.nombreCompleto)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Badge del tipo de empleado
                employeeTypeBadge(tipo: user.tipo)
            }
        }
        .padding(.top)
    }
    
    private func employeeTypeBadge(tipo: Int) -> some View {
        HStack {
            Image(systemName: "person.badge")
                .font(.caption)
            
            Text(getEmployeeTypeText(tipo: tipo))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(primaryColor.opacity(0.1))
        .foregroundColor(primaryColor)
        .cornerRadius(12)
    }
    
    private func personalInfoSection(user: Empleado) -> some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Información Personal")
            
            VStack(spacing: 0) {
                InfoRow(
                    icon: "person",
                    title: "Nombre Completo",
                    value: user.nombreCompleto
                )
                
                Divider()
                    .padding(.leading, 44)
                
                InfoRow(
                    icon: "envelope",
                    title: "Correo Electrónico",
                    value: user.email
                )
                
                Divider()
                    .padding(.leading, 44)
                
                InfoRow(
                    icon: "doc.text",
                    title: "RFC",
                    value: user.rfc
                )
                
                Divider()
                    .padding(.leading, 44)
                
                InfoRow(
                    icon: "person.text.rectangle",
                    title: "CURP",
                    value: user.curp
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func workInfoSection(user: Empleado) -> some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Información Laboral")
            
            VStack(spacing: 0) {
                InfoRow(
                    icon: "number",
                    title: "ID Empleado",
                    value: "\(user.id)"
                )
                
                Divider()
                    .padding(.leading, 44)
                
                InfoRow(
                    icon: "briefcase",
                    title: "Tipo de Empleado",
                    value: getEmployeeTypeText(tipo: user.tipo)
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func appSettingsSection() -> some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Configuración")
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell",
                    title: "Notificaciones",
                    subtitle: "Gestionar alertas de recibos"
                ) {
                    openNotificationSettings()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "info.circle",
                    title: "Acerca de la App",
                    subtitle: "Versión 1.0.0"
                ) {
                    // Mostrar información de la app
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Cerrar Sesión",
                    subtitle: "Salir de la aplicación",
                    isDestructive: true
                ) {
                    logout()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No se pudo cargar la información del usuario")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Funciones auxiliares
    
    private func getEmployeeTypeText(tipo: Int) -> String {
        switch tipo {
        case 1:
            return "Empleado Regular"
        case 2:
            return "Administrador"
        case 3:
            return "Supervisor"
        default:
            return "Empleado"
        }
    }
    
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func logout() {
        dismiss()
        authManager.logout()
    }
}

// MARK: - Componentes auxiliares

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    private let primaryColor = Color(red: 0.373, green: 0.129, blue: 0.192)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
    }
    
    private let primaryColor = Color(red: 0.373, green: 0.129, blue: 0.192)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : primaryColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
