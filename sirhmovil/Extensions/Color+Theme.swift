//
//  Color+Theme.swift
//  sirhmovil
//
//  Created by Carlos Maldonado on 13/08/25.
//

import SwiftUI

extension Color {
    // MARK: - Paleta de colores principal
    static let theme = ColorTheme()
}

struct ColorTheme {
    // Colores principales (tonos bordeaux/vino profesionales)
    let primary = Color(red: 0.573, green: 0.329, blue: 0.392)        // Bordeaux más claro
    let primaryLight = Color(red: 0.25, green: 0.62, blue: 0.52)   // Verde claro #40A085
    let primaryDark = Color(red: 0.15, green: 0.40, blue: 0.30)    // Verde oscuro #26664D
    
    // Colores secundarios
    let secondary = Color(red: 0.45, green: 0.55, blue: 0.60)      // Gris azulado #738C99
    let accent = Color(red: 0.85, green: 0.65, blue: 0.13)        // Dorado #D9A521
    
    // Colores funcionales
    let success = Color(red: 0.22, green: 0.66, blue: 0.37)       // Verde éxito #38A95E
    let warning = Color(red: 0.95, green: 0.61, blue: 0.07)       // Naranja advertencia #F39C12
    let error = Color(red: 0.91, green: 0.30, blue: 0.24)         // Rojo error #E84C3D
    let info = Color(red: 0.20, green: 0.60, blue: 0.86)          // Azul información #3498DB
    
    // Grises
    let gray100 = Color(red: 0.98, green: 0.98, blue: 0.98)       // Gris muy claro
    let gray200 = Color(red: 0.93, green: 0.94, blue: 0.95)       // Gris claro
    let gray300 = Color(red: 0.83, green: 0.84, blue: 0.86)       // Gris medio claro
    let gray400 = Color(red: 0.64, green: 0.66, blue: 0.68)       // Gris medio
    let gray500 = Color(red: 0.46, green: 0.48, blue: 0.51)       // Gris medio oscuro
    let gray600 = Color(red: 0.35, green: 0.37, blue: 0.40)       // Gris oscuro
    
    // Gradientes
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [primaryLight.opacity(0.8), primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Colores semánticos para iconos
extension Color {
    // Iconos principales
    static let iconPrimary = Color.theme.primary
    static let iconSecondary = Color.theme.secondary
    static let iconAccent = Color.theme.accent
    
    // Iconos funcionales
    static let iconSuccess = Color.theme.success     // Para percepciones, éxito
    static let iconWarning = Color.theme.warning     // Para prestaciones, atención
    static let iconError = Color.theme.error         // Para deducciones, errores
    static let iconInfo = Color.theme.info           // Para información general
    
    // Iconos por categoría
    static let iconMoney = Color.theme.success       // Iconos de dinero
    static let iconDocument = Color.theme.primary    // Iconos de documentos
    static let iconUser = Color.theme.primaryDark    // Iconos de usuario
    static let iconChart = Color.theme.accent        // Iconos de estadísticas
    static let iconSettings = Color.theme.secondary  // Iconos de configuración
}
