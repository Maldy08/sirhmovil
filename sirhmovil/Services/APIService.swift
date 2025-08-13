// MARK: - API Service
import Foundation
import Combine

class APIService: ObservableObject {
    private let authority = "juventudbc.com.mx" // Tu dominio
    private var session = URLSession.shared
    
    // MARK: - Login (ACTUALIZADO PARA EMAIL/PASSWORD)
    func login(email: String, password: String, fcmToken: String? = nil) -> AnyPublisher<LoginResponse, Error> {
        let path = "/api/backend/auth/loginMobile"
        
        guard let url = URL(string: "https://\(authority)\(path)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = LoginRequest(email: email, password: password, fcmToken: fcmToken)
        
        do {
            request.httpBody = try JSONEncoder().encode(loginData)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Validar respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Send FCM Token
    func sendFcmToken(_ fcmToken: String, authToken: String) -> AnyPublisher<Void, Error> {
        let path = "/api/backend/notificaciones/guardarToken"
        
        guard let url = URL(string: "https://\(authority)\(path)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let tokenData = ["fcmToken": fcmToken]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: tokenData)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Validar respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return () // Retornamos Void en caso de éxito
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch Recibos
    func fetchRecibos(empleado: Int, tipo: Int, anio: String) -> AnyPublisher<[Recibo], Error> {
        let path = "/api/backend/nomina/recibos/\(empleado)/\(tipo)"
        
        guard let url = URL(string: "https://\(authority)\(path)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                // Validar respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: [Recibo].self, decoder: JSONDecoder())
            .map { recibos in
                // Solo filtrar por año y ordenar - no necesitamos modificar cada recibo
                return recibos
                    .filter { $0.fechaPago.contains(anio) }
                    .sorted { $0.periodo > $1.periodo }
            }
            .mapError { error in
                if error is DecodingError {
                    print("Error decodificando recibos: \(error)")
                    return APIError.decodingError
                }
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch PDF
    func fetchReciboPdf(empleado: Int, periodo: Int, tipo: Int) -> AnyPublisher<Data, Error> {
        let path = "/api/backend/pdf/\(empleado)/\(periodo)/\(tipo)"
        
        guard let url = URL(string: "https://\(authority)\(path)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                // Validar respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - API Models
struct LoginRequest: Codable {
    let email: String
    let password: String
    let fcmToken: String?
}

struct LoginResponse: Codable {
    let token: String
    let empleado: Empleado
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos del servidor"
        case .decodingError:
            return "Error al procesar los datos del servidor"
        case .serverError(let code):
            return "Error del servidor (código \(code))"
        case .networkError:
            return "Error de conexión de red"
        }
    }
}
