import SwiftUI

struct MenuView: View {
    @Binding var showingProfile: Bool
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        dismiss()
                        showingProfile = true
                    }) {
                        Label("Mi Perfil", systemImage: "person.circle")
                    }
                    
//                    NavigationLink(destination: SettingsView()) {
//                        Label("Configuración", systemImage: "gear")
//                    }
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

#Preview {
    MenuView(showingProfile: .constant(false))
        .environmentObject(AuthManager())
}
