//
//  Empleado.swift
//  sirhmovil
//
//  Created by Carlos Maldonado on 10/08/25.
//

import Foundation

struct Empleado: Codable, Identifiable {
    let id: Int
    let nombre: String
    let appat: String
    let apmat: String
    let rfc: String
    let curp: String
    let tipo: Int
    let email: String
    
    // Computed properties equivalentes a los getters de Flutter
    var nombreCompleto: String {
        return "\(nombre) \(appat) \(apmat)"
    }
    
    var iniciales: String {
        guard !nombre.isEmpty, !appat.isEmpty else { return "?" }
        return "\(nombre.prefix(1))\(appat.prefix(1))".uppercased()
    }
    
    // CodingKeys para mapear los nombres JSON del backend
    enum CodingKeys: String, CodingKey {
        case id = "EMPLEADO"
        case nombre = "NOMBRE"
        case appat = "APPAT"
        case apmat = "APMAT"
        case rfc = "RFC"
        case curp = "CURP"
        case tipo = "TIPO"
        case email = "EMAIL"
    }
}

// MARK: - Ejemplo de uso y testing
extension Empleado {
    // Empleado de ejemplo para preview y testing
    static let preview = Empleado(
        id: 3,
        nombre: "ORALIA",
        appat: "URIBE",
        apmat: "GONZALEZ",
        rfc: "UIGO630717VC2",
        curp: "UIGO630717MJCRNR05",
        tipo: 1,
        email: "oralia.uribe@example.com"
    )
}
