//
//  Recibo.swift
//  sirhmovil
//
//  Created by Carlos Maldonado on 10/08/25.
//

import Foundation

struct Recibo: Codable, Identifiable {
    let id = UUID() // SwiftUI necesita un ID único para las listas
    let empleado: Int
    let periodo: Int
    let fechaPago: String
    let percepciones: Double
    let prestaciones: Double // NUEVO CAMPO agregado en tu última versión
    let deducciones: Double
    let neto: Double
  //  let tipo: Int
    
    // CodingKeys para el JSON (excluimos 'id' porque es generado localmente)
    enum CodingKeys: String, CodingKey {
        case empleado, periodo, fechaPago, percepciones, prestaciones, deducciones, neto
    }
    
    // Inicializador personalizado para manejar el parsing de monedas
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        empleado = try container.decode(Int.self, forKey: .empleado)
        periodo = try container.decode(Int.self, forKey: .periodo)
        fechaPago = try container.decode(String.self, forKey: .fechaPago)
       // tipo = try container.decode(Int.self, forKey: .tipo)
        
        // Parsing de monedas como en tu Flutter (strings que pueden tener $, comas, etc.)
        let percepcionesString = try container.decode(String.self, forKey: .percepciones)
        let prestacionesString = try container.decode(String.self, forKey: .prestaciones)
        let deduccionesString = try container.decode(String.self, forKey: .deducciones)
        let netoString = try container.decode(String.self, forKey: .neto)
        
        percepciones = Self.parseCurrency(percepcionesString)
        prestaciones = Self.parseCurrency(prestacionesString)
        deducciones = Self.parseCurrency(deduccionesString)
        neto = Self.parseCurrency(netoString)
    }
    
    // Inicializador directo para cuando ya tenemos los valores como Double
    init(empleado: Int, periodo: Int, fechaPago: String, percepciones: Double, prestaciones: Double, deducciones: Double, neto: Double) {
        self.empleado = empleado
        self.periodo = periodo
        self.fechaPago = fechaPago
        self.percepciones = percepciones
        self.prestaciones = prestaciones
        self.deducciones = deducciones
        self.neto = neto
        //self.tipo = tipo
    }
    
    // Función auxiliar para parsear strings de moneda
    private static func parseCurrency(_ currencyString: String) -> Double {
        // Elimina símbolos de moneda, comas y espacios como en tu Flutter
        let sanitizedString = currencyString.replacingOccurrences(of: "[$,\\s]", with: "", options: .regularExpression)
        return Double(sanitizedString) ?? 0.0
    }
}

// MARK: - Extensiones útiles
extension Recibo {
    // Formateador de periodo como en tu Flutter actualizado
    var formatoPeriodo: String {
        let periodoStr = String(periodo).padding(toLength: 6, withPad: "0", startingAt: 0)
        guard periodoStr.count >= 6 else { return "Periodo: \(periodo)" }
        
        let anio = String(periodoStr.prefix(4))
        let quincena = String(periodoStr.suffix(2))
        return "Periodo \(quincena)"
    }
    
    // Función para generar datos dummy como en tu Flutter (útil para testing)
    static func getDummyRecibos() -> [Recibo] {
        return (0..<10).map { index in
            let percepciones = 20000.0 + Double.random(in: 0...5000)
            let prestaciones = 1000.0 + Double.random(in: 0...500)
            let deducciones = 4000.0 + Double.random(in: 0...1000)
            let neto = percepciones + prestaciones - deducciones
            
            return Recibo(
                empleado: 123,
                periodo: 202501 + index,
                fechaPago: "15/01/2025",
                percepciones: percepciones,
                prestaciones: prestaciones,
                deducciones: deducciones,
                neto: neto,
           //     tipo: 1
            )
        }
    }
    
    // Recibo de ejemplo para previews
    static let preview = Recibo(
        empleado: 123,
        periodo: 202501,
        fechaPago: "15/01/2025",
        percepciones: 25000.0,
        prestaciones: 1500.0,
        deducciones: 4500.0,
        neto: 22000.0,
      //  tipo: 1
    )
}
