//
//  Color + Extension.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI


extension Color {
    static let appBackground = Color(hex: "#1d1f21")
    static let cardBackground = Color(hex: "#303236")
    static let sectionHeaderBackground = Color(hex: "#393B40")
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "#B0B3B8")
    static let accentCol = Color(hex: "#0075a5")
    static let buttonTextOnYellow = Color(hex: "#393B40")

    static let levelRed = Color(hex: "#E54646")
    static let levelOrange = Color(hex: "#F0903D")
    static let levelGreen = Color(hex: "#58B85D")
    static let levelYellowOrange = Color(hex: "#F7A83B")
    static let levelBlue = Color(hex: "#4A90E2")
    static let levelPurple = Color(hex: "#8B57F7")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct AppFontName {
    static let aclonicaRegular = "Aclonica-Regular"
}


