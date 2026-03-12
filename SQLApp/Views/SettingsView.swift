import SwiftUI

/// The settings screen where users can customize the SQL editor's appearance.
///
/// Currently provides a single setting: the color used to highlight SQL keywords
/// in the editor. The chosen color is persisted across app launches via
/// ``SettingsViewModel`` and `UserDefaults`.
///
/// Includes a live preview section showing sample SQL text in the selected
/// keyword color and semibold weight, so users can see the effect immediately.
///
/// Displayed as a tab in the root ``ContentView`` tab bar.
struct SettingsView: View {

    /// The ViewModel that manages settings persistence and state.
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ColorPicker(
                        "Keyword Color",
                        selection: $viewModel.keywordColor,
                        supportsOpacity: false
                    )
                } header: {
                    Text("SQL Editor")
                } footer: {
                    Text("Color applied to SQL keywords like SELECT, FROM, WHERE, etc.")
                }

                Section("Preview") {
                    Text(highlightedPreview)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Preview Highlighting

    /// Sample SQL text displayed in the preview section.
    private static let previewSQL = """
        SELECT COUNT(*) AS total
        FROM grades
        WHERE semester = '2026-2'
        GROUP BY name
        HAVING AVG(grade) >= 9.5
        ORDER BY score DESC;
        """

    /// Builds an `AttributedString` where only SQL keywords appear in the
    /// user-chosen color with semibold weight; all other text uses the
    /// default label color and regular weight — matching the editor behavior.
    private var highlightedPreview: AttributedString {
        let plain = Self.previewSQL
        var result = AttributedString()
        let keywordFont = Font.system(.body, design: .monospaced).weight(.semibold)
        let color = viewModel.keywordColor

        // Walk through regex matches, appending non-keyword gaps and keyword
        // segments with the appropriate attributes.
        guard let regex = try? NSRegularExpression(
            pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b"
        ) else {
            return AttributedString(plain)
        }

        let nsString = plain as NSString
        let matches = regex.matches(
            in: plain,
            range: NSRange(location: 0, length: nsString.length)
        )

        var cursor = plain.startIndex
        for match in matches {
            guard let matchRange = Range(match.range, in: plain) else { continue }

            // Append any text before this match as plain
            if cursor < matchRange.lowerBound {
                result.append(AttributedString(plain[cursor..<matchRange.lowerBound]))
            }

            // Check if the word is a keyword
            let word = String(plain[matchRange]).uppercased()
            var segment = AttributedString(plain[matchRange])
            if SQLKeywords.all.contains(word) {
                segment.foregroundColor = color
                segment.font = keywordFont
            }
            result.append(segment)
            cursor = matchRange.upperBound
        }

        // Append any remaining text after the last match
        if cursor < plain.endIndex {
            result.append(AttributedString(plain[cursor..<plain.endIndex]))
        }

        return result
    }
}
