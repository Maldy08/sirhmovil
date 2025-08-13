// PDFViewerView.swift
import SwiftUI
import PDFKit
import Combine

// MARK: - ViewModel para PDF
class PDFViewModel: ObservableObject {
    @Published var pdfData: Data?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    func loadPDF(empleado: Int, periodo: Int, tipo: Int) {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchReciboPdf(empleado: empleado, periodo: periodo, tipo: tipo)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] data in
                    self?.pdfData = data
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Vista Principal del PDF
struct PDFViewerView: View {
    let empleado: Int
    let periodo: Int
    let tipo: Int // ← Lo recibimos como parámetro separado
    
    @StateObject private var viewModel = PDFViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(error: errorMessage)
                } else if let pdfData = viewModel.pdfData {
                    PDFKitView(data: pdfData)
                        .ignoresSafeArea(.container, edges: .bottom)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Recibo Periodo \(periodo)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.pdfData != nil {
                        Button(action: sharePDF) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = viewModel.pdfData {
                ShareSheet(items: [createPDFFile(from: pdfData)])
            }
        }
        .onAppear {
            loadPDF()
        }
    }
    
    // MARK: - Subvistas
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando PDF...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Periodo \(periodo)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error al cargar el PDF")
                .font(.headline)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Reintentar") {
                loadPDF()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("PDF no disponible")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Funciones
    
    private func loadPDF() {
        viewModel.loadPDF(empleado: empleado, periodo: periodo, tipo: tipo)
    }
    
    private func sharePDF() {
        showingShareSheet = true
    }
    
    private func createPDFFile(from data: Data) -> URL {
        let fileName = "recibo_periodo_\(periodo).pdf"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error creando archivo temporal: \(error)")
        }
        
        return fileURL
    }
}

// MARK: - PDFKit Integration
struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configuración de la vista PDF
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        
        // Cargar el documento PDF
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No necesitamos actualizar nada aquí
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configurar para iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {
        // No necesitamos actualizar nada aquí
    }
}

// MARK: - Vista de Recibo (para uso desde RecibosView)

