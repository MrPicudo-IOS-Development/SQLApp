//
//  AppStyle.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 20/03/26.
//

import SwiftUI

/// Defines the 5 visual styles available for the entire app.
///
/// Each case provides a complete color palette used to theme the SQL editor,
/// results table, exercise cards, and other UI elements. The selected style
/// is persisted via ``SettingsViewModel`` and applied throughout the app.
///
/// Color palettes were generated using the UI UX Pro Max design skill.
enum AppStyle: String, CaseIterable, Identifiable, Codable {
    case vibrant
    case glassmorphism
    case minimalism
    case darkMode
    case bentoGrid

    var id: String { rawValue }

    // MARK: - Display Metadata

    /// Human-readable name shown in the style picker.
    var name: String {
        switch self {
        case .vibrant: "Vibrant & Block"
        case .glassmorphism: "Glassmorphism"
        case .minimalism: "Minimalism"
        case .darkMode: "Dark Mode"
        case .bentoGrid: "Bento Grid"
        }
    }

    /// SF Symbol icon for the style picker.
    var icon: String {
        switch self {
        case .vibrant: "square.grid.3x3.fill"
        case .glassmorphism: "rectangle.on.rectangle"
        case .minimalism: "minus.circle"
        case .darkMode: "moon.fill"
        case .bentoGrid: "square.grid.2x2"
        }
    }

    /// Short description of the visual style.
    var description: String {
        switch self {
        case .vibrant: "Bold, energetic, block layout with geometric shapes and high color contrast."
        case .glassmorphism: "Frosted glass effects with transparency, blur backgrounds, and subtle borders."
        case .minimalism: "Clean, focused, generous whitespace. Content takes center stage."
        case .darkMode: "OLED-optimized dark surfaces with vibrant accent colors for dev tools."
        case .bentoGrid: "Modular grid layout inspired by Japanese bento boxes for feature showcases."
        }
    }

    // MARK: - Editor Colors

    /// Main background color for the SQL editor area.
    var editorBackground: Color {
        switch self {
        case .vibrant: Color(hex: 0x0F172A)
        case .glassmorphism: Color(hex: 0x1E1B4B)
        case .minimalism: Color(hex: 0xF8FAFC)
        case .darkMode: Color(hex: 0x0F172A)
        case .bentoGrid: Color(hex: 0x020617)
        }
    }

    /// Color for the terminal-style title bar and control bar.
    var editorTitleBar: Color {
        switch self {
        case .vibrant: Color(hex: 0x1E293B)
        case .glassmorphism: Color(hex: 0x312E81)
        case .minimalism: Color(hex: 0xE2E8F0)
        case .darkMode: Color(hex: 0x1E293B)
        case .bentoGrid: Color(hex: 0x0F172A)
        }
    }

    /// Color applied to SQL keywords in the editor and preview.
    var editorKeywordColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E)
        case .glassmorphism: Color(hex: 0x818CF8)
        case .minimalism: Color(hex: 0x64748B)
        case .darkMode: Color(hex: 0xF59E0B)
        case .bentoGrid: Color(hex: 0xEF4444)
        }
    }

    /// Primary text color inside the editor.
    var editorTextColor: Color {
        switch self {
        case .vibrant: Color(hex: 0xF8FAFC)
        case .glassmorphism: Color(hex: 0xF8FAFC)
        case .minimalism: Color(hex: 0x1E293B)
        case .darkMode: Color(hex: 0xF8FAFC)
        case .bentoGrid: Color(hex: 0xF8FAFC)
        }
    }

    /// Secondary/muted text color (file names, messages).
    var editorSecondaryText: Color {
        switch self {
        case .vibrant: Color(hex: 0x94A3B8)
        case .glassmorphism: Color(hex: 0xA5B4FC)
        case .minimalism: Color(hex: 0x94A3B8)
        case .darkMode: Color(hex: 0x94A3B8)
        case .bentoGrid: Color(hex: 0x94A3B8)
        }
    }

    /// Background color for the Run button.
    var runButtonColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E)
        case .glassmorphism: Color(hex: 0x10B981)
        case .minimalism: Color(hex: 0x64748B)
        case .darkMode: Color(hex: 0x22C55E)
        case .bentoGrid: Color(hex: 0x22C55E)
        }
    }

    /// Text color inside the Run button.
    var runButtonTextColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x0F172A)
        case .glassmorphism: .white
        case .minimalism: .white
        case .darkMode: Color(hex: 0x0F172A)
        case .bentoGrid: Color(hex: 0x0F172A)
        }
    }

    /// The main accent color used across the app (keyword capsules, headers, etc.).
    var accentColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E)
        case .glassmorphism: Color(hex: 0x818CF8)
        case .minimalism: Color(hex: 0x64748B)
        case .darkMode: Color(hex: 0xF59E0B)
        case .bentoGrid: Color(hex: 0xEF4444)
        }
    }

    /// Color for table header text in ResultsTableView.
    var tableHeaderTextColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E)
        case .glassmorphism: Color(hex: 0x818CF8)
        case .minimalism: Color(hex: 0x64748B)
        case .darkMode: Color(hex: 0xF59E0B)
        case .bentoGrid: Color(hex: 0xEF4444)
        }
    }

    /// The color scheme for the editor (dark or light).
    var editorColorScheme: ColorScheme {
        switch self {
        case .vibrant: .dark
        case .glassmorphism: .dark
        case .minimalism: .light
        case .darkMode: .dark
        case .bentoGrid: .dark
        }
    }

    // MARK: - Table Colors

    /// Background for the table header row.
    var tableHeaderBackground: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E)
        case .glassmorphism: Color(hex: 0x312E81).opacity(0.6)
        case .minimalism: .clear
        case .darkMode: Color(hex: 0x000000)
        case .bentoGrid: Color(hex: 0x0F172A)
        }
    }

    /// Text color for table header cells.
    var tableHeaderText: Color {
        switch self {
        case .vibrant: Color(hex: 0x0F172A)
        case .glassmorphism: Color(hex: 0xC7D2FE)
        case .minimalism: Color(hex: 0x1E293B)
        case .darkMode: Color(hex: 0xF59E0B)
        case .bentoGrid: Color(hex: 0xEF4444)
        }
    }

    /// Main background for the table body area.
    var tableBackground: Color {
        switch self {
        case .vibrant: Color(hex: 0x0F172A)
        case .glassmorphism: Color(hex: 0x1E1B4B).opacity(0.4)
        case .minimalism: .white
        case .darkMode: Color(hex: 0x000000)
        case .bentoGrid: Color(hex: 0x020617)
        }
    }

    /// Primary text color for data cells.
    var tableDataText: Color {
        switch self {
        case .vibrant: Color(hex: 0xF8FAFC)
        case .glassmorphism: Color(hex: 0xE0E7FF)
        case .minimalism: Color(hex: 0x334155)
        case .darkMode: Color(hex: 0xE2E8F0)
        case .bentoGrid: Color(hex: 0xE2E8F0)
        }
    }

    /// Background for even-numbered data rows (alternating pattern).
    var tableRowEvenBackground: Color {
        switch self {
        case .vibrant: Color(hex: 0x1E293B)
        case .glassmorphism: Color.white.opacity(0.05)
        case .minimalism: .white
        case .darkMode: Color(hex: 0x0A0A0A)
        case .bentoGrid: Color(hex: 0x0F172A)
        }
    }

    /// Background for odd-numbered data rows (alternating pattern).
    var tableRowOddBackground: Color {
        switch self {
        case .vibrant: Color(hex: 0x0F172A)
        case .glassmorphism: Color.white.opacity(0.02)
        case .minimalism: .white
        case .darkMode: Color(hex: 0x000000)
        case .bentoGrid: Color(hex: 0x020617)
        }
    }

    /// Color for separator lines between rows.
    var tableSeparatorColor: Color {
        switch self {
        case .vibrant: Color(hex: 0x22C55E).opacity(0.3)
        case .glassmorphism: Color.white.opacity(0.1)
        case .minimalism: Color(hex: 0xE2E8F0)
        case .darkMode: Color(hex: 0x1E293B)
        case .bentoGrid: Color(hex: 0x1E293B)
        }
    }

    /// Border color for cells (used by Bento Grid and Glassmorphism).
    var tableBorderColor: Color {
        switch self {
        case .vibrant: .clear
        case .glassmorphism: Color.white.opacity(0.15)
        case .minimalism: .clear
        case .darkMode: .clear
        case .bentoGrid: Color(hex: 0x1E293B)
        }
    }

    /// Corner radius used for the overall table container.
    var tableCornerRadius: CGFloat {
        switch self {
        case .vibrant: 12
        case .glassmorphism: 16
        case .minimalism: 0
        case .darkMode: 8
        case .bentoGrid: 12
        }
    }
}
