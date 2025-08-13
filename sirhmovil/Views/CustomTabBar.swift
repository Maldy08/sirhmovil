// CustomTabBar.swift
import SwiftUI

// MARK: - Tab Bar Principal con Menú
struct CustomTabBarView: View {
    @State private var selectedTab = 0
    @State private var showingMenu = false
    @State private var showingProfile = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido principal
            TabView(selection: $selectedTab) {
                // Tab 1: Inicio
                NavigationView {
                    EnhancedRecibosView()
                }
                .tag(0)
                
                // Tab 2: Historial
                NavigationView {
                    HistorialView()
                }
                .tag(1)
                
                // Tab 3: Notificaciones
                NavigationView {
                    NotificationsView()
                }
                .tag(2)
                
                // Tab 4: Más (Menú)
                NavigationView {
                    MoreMenuView(
                        showingProfile: $showingProfile
                    )
                }
                .tag(3)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, showingMenu: $showingMenu)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingMenu) {
            MenuSheet()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Custom Tab Bar Component
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showingMenu: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryColor: Color {
        Color(red: 0.373, green: 0.129, blue: 0.192)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Inicio
            TabBarButton(
                icon: "house.fill",
                title: "Inicio",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // Historial
            TabBarButton(
                icon: "clock.fill",
                title: "Historial",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // Notificaciones con badge
            TabBarButtonWithBadge(
                icon: "bell.fill",
                title: "Alertas",
                isSelected: selectedTab == 2,
                badgeCount: 3,
                action: { selectedTab = 2 }
            )
            
            // Más opciones
            TabBarButton(
                icon: "ellipsis.circle.fill",
                title: "Más",
                isSelected: selectedTab == 3,
                action: {
                    selectedTab = 3
                    // O puedes mostrar un menú emergente
                    // showingMenu = true
                }
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private var primaryColor: Color {
        Color(red: 0.373, green: 0.129, blue: 0.192)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? primaryColor : .gray)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? primaryColor : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Bar Button with Badge
struct TabBarButtonWithBadge: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void
    
    private var primaryColor: Color {
        Color(red: 0.373, green: 0.129, blue: 0.192)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? primaryColor : .gray)
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -4)
                    }
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? primaryColor : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - More Menu View (Grid Style)
struct MoreMenuView: View {
    @Binding var showingProfile: Bool
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con información del usuario
                userHeader
                
                // Grid de opciones
                LazyVGrid(columns: columns, spacing: 20) {
                    MenuGridItem(
                        icon: "person.fill",
                        title: "Mi Perfil",
                        color: .blue,
                        action: { showingProfile = true }
                    )
                    
                    MenuGridItem(
                        icon: "gearshape.fill",
                        title: "Ajustes",
                        color: .gray,
                        action: { showingSettings = true }
                    )
                    
                    MenuGridItem(
                        icon: "doc.text.fill",
                        title: "Documentos",
                        color: .green,
                        action: { }
                    )
                    
                    MenuGridItem(
                        icon: "calendar",
                        title: "Calendario",
                        color: .orange,
                        action: { }
                    )
                    
                    MenuGridItem(
                        icon: "questionmark.circle.fill",
                        title: "Ayuda",
                        color: .purple,
                        action: { showingHelp = true }
                    )
                    
                    MenuGridItem(
                        icon: "info.circle.fill",
                        title: "Acerca de",
                        color: .indigo,
                        action: { showingAbout = true }
                    )
                }
                .padding(.horizontal)
                
                // Sección adicional con lista
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuración rápida")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        MenuListItem(
                            icon: "bell",
                            title: "Notificaciones",
                            subtitle: "Gestionar alertas",
                            showToggle: true
                        )
                        
                        Divider()
                        
                        MenuListItem(
                            icon: "faceid",
                            title: "Biometría",
                            subtitle: "Face ID / Touch ID",
                            showToggle: true
                        )
                        
                        Divider()
                        
                        MenuListItem(
                            icon: "moon.fill",
                            title: "Modo Oscuro",
                            subtitle: "Tema de la aplicación",
                            showToggle: true
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Botón de logout
                logoutButton
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("Más opciones")
        .background(Color(.systemGroupedBackground))
    }
    
    private var userHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(authManager.currentUser?.iniciales ?? "??")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.nombreCompleto ?? "Usuario")
                    .font(.headline)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var logoutButton: some View {
        Button(action: {
            authManager.logout()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Cerrar Sesión")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// MARK: - Menu Grid Item
struct MenuGridItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu List Item
struct MenuListItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let showToggle: Bool
    @State private var isOn = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if showToggle {
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Placeholder Views
struct HistorialView: View {
    var body: some View {
        Text("Historial")
            .navigationTitle("Historial")
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notificaciones")
            .navigationTitle("Notificaciones")
    }
}

// MARK: - Menu Sheet (Alternativa)
struct MenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Cuenta") {
                    Label("Mi Perfil", systemImage: "person.fill")
                    Label("Configuración", systemImage: "gearshape.fill")
                }
                
                Section("Documentos") {
                    Label("Recibos", systemImage: "doc.text.fill")
                    Label("Constancias", systemImage: "doc.badge.plus")
                    Label("Historial", systemImage: "clock.fill")
                }
                
                Section("Soporte") {
                    Label("Ayuda", systemImage: "questionmark.circle.fill")
                    Label("Contacto", systemImage: "envelope.fill")
                }
                
                Section {
                    Button(action: {
                        dismiss()
                        authManager.logout()
                    }) {
                        Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Menú")
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
}

// MARK: - Preview
#Preview {
    CustomTabBarView()
        .environmentObject(AuthManager())
}
