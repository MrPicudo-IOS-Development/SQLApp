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
                    Text(previewText)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundStyle(viewModel.keywordColor)
                }
            }
            .navigationTitle("Settings")
        }
    }

    /// Sample SQL text displayed in the preview section.
    private var previewText: String {
        "SELECT * FROM users WHERE id = 1;"
    }
}
