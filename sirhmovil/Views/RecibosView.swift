// EnhancedRecibosView.swift
import SwiftUI
import Combine

// MARK: - ViewModel mejorado
class EnhancedRecibosViewModel: ObservableObject {
    @Published var recibos: [Recibo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedYear = "2025"
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var sortOption: SortOption = .periodoDesc
    @Published var showingFilters = false
    
    // Estadísticas
    @Published var totalPercepciones: Double = 0
    @Published var totalPrestaciones: Double = 0
    @Published var totalDeducciones: Double = 0
    @Published var totalNeto: Double = 0
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    let availableYears = ["2025", "2024"]
    
    enum SortOption: String, CaseIterable {
        case periodoDesc = "Periodo (Reciente)"
        case periodoAsc = "Periodo (Antiguo)"
        case netoDesc = "Neto (Mayor)"
        case netoAsc = "Neto (Menor)"
        case fechaDesc = "Fecha (Reciente)"
        case fechaAsc = "Fecha (Antiguo)"
    }
    
    // Recibos filtrados y ordenados
    var filteredAndSortedRecibos: [Recibo] {
        var filtered = recibos
        
        // Filtrar por búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter { recibo in
                String(recibo.periodo).localizedCaseInsensitiveContains(searchText) ||
                recibo.fechaPago.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Ordenar
        switch sortOption {
        case .periodoDesc:
            return filtered.sorted { $0.periodo > $1.periodo }
        case .periodoAsc:
            return filtered.sorted { $0.periodo < $1.periodo }
        case .netoDesc:
            return filtered.sorted { $0.neto > $1.neto }
        case .netoAsc:
            return filtered.sorted { $0.neto < $1.neto }
        case .fechaDesc:
            return filtered.sorted { $0.fechaPago > $1.fechaPago }
        case .fechaAsc:
            return filtered.sorted { $0.fechaPago < $1.fechaPago }
        }
    }
    
    func loadRecibos(empleado: Int, tipo: Int) {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchRecibos(empleado: empleado, tipo: tipo, anio: selectedYear)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Error cargando recibos: \(error)")
                    }
                },
                receiveValue: { [weak self] recibos in
                    self?.recibos = recibos
                    self?.calculateStatistics()
                    print("✅ Recibos cargados: \(recibos.count)")
                }
            )
            .store(in: &cancellables)
    }
    
    private func calculateStatistics() {
        totalPercepciones = recibos.reduce(0) { $0 + $1.percepciones }
        totalPrestaciones = recibos.reduce(0) { $0 + $1.prestaciones }
        totalDeducciones = recibos.reduce(0) { $0 + $1.deducciones }
        totalNeto = recibos.reduce(0) { $0 + $1.neto }
    }
    
    func clearSearch() {
        searchText = ""
        isSearching = false
    }
    
    func exportData() -> String {
        // Generar CSV de los recibos para compartir
        var csv = "Periodo,Fecha de Pago,Percepciones,Prestaciones,Deducciones,Neto\n"
        
        for recibo in filteredAndSortedRecibos {
            csv += "\(recibo.periodo),\(recibo.fechaPago),\(recibo.percepciones),\(recibo.prestaciones),\(recibo.deducciones),\(recibo.neto)\n"
        }
        
        return csv
    }
}

// MARK: - Vista Principal Mejorada
struct EnhancedRecibosView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EnhancedRecibosViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    @State private var showingProfile = false
    @State private var showingMenu = false
    @State private var showPermissionAlert = false
    @State private var selectedRecibo: Recibo?
    @State private var showingExportSheet = false
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationView {
            MainLayout {
                VStack(spacing: 0) {
                    // Barra de búsqueda mejorada
                    if viewModel.isSearching {
                        enhancedSearchBar
                    }
                    
                    // Banner de estadísticas (opcional)
                    if showingStatistics && !viewModel.recibos.isEmpty {
                        statisticsBanner
                    }
                    
                    // Contenido principal
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        contentView
                    }
                }
            }
            .navigationTitle("Mis Recibos")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingMenu = true }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Botón de estadísticas
                    Button(action: { showingStatistics.toggle() }) {
                        Image(systemName: showingStatistics ? "chart.bar.fill" : "chart.bar")
                    }
                    
                    // Botón de búsqueda
                    Button(action: toggleSearch) {
                        Image(systemName: viewModel.isSearching ? "xmark" : "magnifyingglass")
                    }
                    
                    // Menú de opciones
                    Menu {
                        // Selector de año
                        Menu("Año") {
                            ForEach(viewModel.availableYears, id: \.self) { year in
                                Button(year) {
                                    viewModel.selectedYear = year
                                    loadRecibos()
                                }
                            }
                        }
                        
                        // Opciones de ordenamiento
                        Menu("Ordenar por") {
                            ForEach(EnhancedRecibosViewModel.SortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    viewModel.sortOption = option
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Actualizar
                        Button(action: loadRecibos) {
                            Label("Actualizar", systemImage: "arrow.clockwise")
                        }
                        .requiresConnection()
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingMenu) {
            MenuView(showingProfile: $showingProfile)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authManager)
        }
        .sheet(item: $selectedRecibo) { recibo in
            if let empleado = authManager.currentUser {
                PDFViewerView(
                    empleado: recibo.empleado,
                    periodo: recibo.periodo,
                    tipo: empleado.tipo
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(csvData: viewModel.exportData(), year: viewModel.selectedYear)
        }
        .onAppear {
            loadRecibos()
            checkNotificationPermissions()
            setupNotificationListener()
        }
        .alert("Activar Notificaciones", isPresented: $showPermissionAlert) {
            Button("Ahora no", role: .cancel) { }
            Button("Ir a Ajustes") {
                openAppSettings()
            }
        } message: {
            Text("Para recibir alertas cuando tus recibos de nómina estén listos, por favor, activa las notificaciones en los ajustes de la aplicación.")
        }
    }
    
    // MARK: - Subvistas Mejoradas
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.recibos.isEmpty {
            LoadingView(message: "Cargando recibos para \(viewModel.selectedYear)...")
        } else if let error = viewModel.errorMessage {
            ErrorView(
                title: "Error al cargar recibos",
                message: error,
                retryAction: loadRecibos,
                isConnected: connectivityManager.isConnected
            )
        } else if viewModel.filteredAndSortedRecibos.isEmpty {
            EmptyStateView(
                searchText: viewModel.searchText,
                year: viewModel.selectedYear,
                retryAction: loadRecibos
            )
        } else {
            recibosListView
        }
    }
    
    private var enhancedSearchBar: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Buscar por periodo o fecha...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Cancelar") {
                    toggleSearch()
                }
            }
            
            // Contador de resultados
            if !viewModel.searchText.isEmpty {
                HStack {
                    Text("\(viewModel.filteredAndSortedRecibos.count) resultados")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewModel.filteredAndSortedRecibos.count != viewModel.recibos.count {
                        Button("Limpiar filtro") {
                            viewModel.clearSearch()
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
    
    private var statisticsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Percepciones",
                    amount: viewModel.totalPercepciones,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                
                StatCard(
                    title: "Total Prestaciones",
                    amount: viewModel.totalPrestaciones,
                    color: .blue,
                    icon: "gift.circle.fill"
                )
                
                StatCard(
                    title: "Total Deducciones",
                    amount: viewModel.totalDeducciones,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
                
                StatCard(
                    title: "Total Neto",
                    amount: viewModel.totalNeto,
                    color: .primary,
                    icon: "dollarsign.circle.fill"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var recibosListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAndSortedRecibos) { recibo in
                    EnhancedReciboListItem(recibo: recibo) {
                        selectedRecibo = recibo
                    }
                }
            }
            .padding()
        }
        .refreshable {
            loadRecibos()
        }
    }
    
    // MARK: - Funciones
    
    private func toggleSearch() {
        withAnimation {
            viewModel.isSearching.toggle()
            if !viewModel.isSearching {
                viewModel.searchText = ""
            }
        }
    }
    
    private func loadRecibos() {
        guard let empleado = authManager.currentUser else { return }
        viewModel.loadRecibos(empleado: empleado.id, tipo: empleado.tipo)
    }
    
    private func exportData() {
        showingExportSheet = true
    }
    
    private func checkNotificationPermissions() {
        Task {
            let hasPermission = await notificationManager.checkNotificationPermission()
            if !hasPermission {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func setupNotificationListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToPDF"),
            object: nil,
            queue: .main
        ) { notification in
            if let data = notification.object as? [String: Int],
               let empleado = data["empleado"],
               let periodo = data["periodo"],
               let _ = authManager.currentUser {
                
                let recibo = Recibo(
                    empleado: empleado,
                    periodo: periodo,
                    fechaPago: "",
                    percepciones: 0,
                    prestaciones: 0,
                    deducciones: 0,
                    neto: 0
                )
                
                selectedRecibo = recibo
            }
        }
    }
}

// MARK: - Componentes auxiliares

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(amount, format: .currency(code: "MXN"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .frame(minWidth: 120)
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isConnected ? "exclamationmark.triangle" : "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(isConnected ? .orange : .red)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if isConnected {
                Button("Reintentar") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Verifica tu conexión a internet")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    let searchText: String
    let year: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ?
                 "No hay recibos disponibles para \(year)" :
                 "No se encontraron recibos para \"\(searchText)\"")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button("Actualizar") {
                    retryAction()
                }
                .buttonStyle(.bordered)
                .requiresConnection()
            }
        }
        .padding()
    }
}

struct EnhancedReciboListItem: View {
    let recibo: Recibo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header con gradiente
                headerView
                
                // Contenido
                contentView
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recibo.formatoPeriodo)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Fecha de pago: \(recibo.fechaPago)")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // Neto a pagar (destacado)
            netoSection
            
            // Detalles en columnas
            HStack(spacing: 8) {
                amountColumn(
                    icon: "arrow.up.circle.fill",
                    title: "Percepciones",
                    amount: recibo.percepciones,
                    color: .green
                )
                
                amountColumn(
                    icon: "gift.circle.fill",
                    title: "Prestaciones",
                    amount: recibo.prestaciones,
                    color: .blue
                )
                
                amountColumn(
                    icon: "arrow.down.circle.fill",
                    title: "Deducciones",
                    amount: recibo.deducciones,
                    color: .red
                )
            }
        }
        .padding()
    }
    
    private var netoSection: some View {
        VStack(spacing: 4) {
            Text("NETO A PAGAR")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(recibo.neto, format: .currency(code: "MXN"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func amountColumn(icon: String, title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Text(amount, format: .currency(code: "MXN"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Views temporales (debes crear archivos separados para estos)
struct MenuView: View {
    @Binding var showingProfile: Bool
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button("Mi Perfil") {
                    dismiss()
                    showingProfile = true
                }
                
                Button("Cerrar Sesión") {
                    dismiss()
                    authManager.logout()
                }
                .foregroundColor(.red)
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


struct ExportSheet: View {
    let csvData: String
    let year: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Exportar Recibos \(year)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Se exportarán todos los recibos del año en formato CSV")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                ShareLink(
                    item: csvData,
                    preview: SharePreview("Recibos \(year).csv")
                ) {
                    Label("Compartir CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Exportar")
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



// MARK: - Extensiones necesarias
