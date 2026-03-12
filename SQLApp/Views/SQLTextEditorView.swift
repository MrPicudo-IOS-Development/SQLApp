import SwiftUI

/// A SwiftUI-compatible SQL text editor with syntax highlighting.
///
/// Wraps a `UITextView` via `UIViewRepresentable` to support
/// `NSAttributedString`-based rendering, which is not possible with
/// SwiftUI's built-in `TextEditor`. Provides:
/// - **Syntax highlighting**: SQL keywords displayed in a configurable
///   color with semibold weight via ``SQLSyntaxHighlighter``.
/// - **Auto-uppercase**: SQL keywords automatically uppercased when
///   the user types a word-boundary character.
/// - **Focus binding**: Communicates first-responder status back to SwiftUI,
///   replacing `@FocusState` which is unavailable for `UIViewRepresentable`.
///
/// The plain `String` binding remains the source of truth in the ViewModel;
/// the `NSAttributedString` is a derived visual representation applied
/// only to the `UITextView` layer.
struct SQLTextEditorView: UIViewRepresentable {

    /// Binding to the plain SQL text string owned by the ViewModel.
    @Binding var text: String

    /// Binding that tracks whether the editor currently has keyboard focus.
    /// Replaces `@FocusState` for UIKit-backed views.
    @Binding var isFocused: Bool

    /// The color used to highlight SQL keywords, provided by ``SettingsViewModel``.
    var keywordColor: UIColor

    // MARK: - UIViewRepresentable

    /// Creates the `UITextView` with initial configuration matching the app's editor style.
    ///
    /// Configures the text view with a monospaced font, light gray background,
    /// and disabled autocorrection/autocapitalization to avoid interfering with SQL input.
    ///
    /// - Parameter context: The representable context containing the coordinator.
    /// - Returns: A configured `UITextView` instance.
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = SQLSyntaxHighlighter.baseFont
        textView.backgroundColor = .systemGray6
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardType = .asciiCapable

        textView.attributedText = SQLSyntaxHighlighter.highlight(
            text,
            keywordColor: keywordColor
        )

        return textView
    }

    /// Updates the `UITextView` when SwiftUI state changes externally.
    ///
    /// Only updates the text view if the plain text has actually changed
    /// (e.g., via the Clear button or loading from history), preventing
    /// unnecessary re-highlighting and cursor jumps. Also updates the
    /// coordinator's keyword color and manages first-responder status.
    ///
    /// - Parameters:
    ///   - textView: The `UITextView` to update.
    ///   - context: The representable context containing the coordinator.
    func updateUIView(_ textView: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.keywordColor = keywordColor

        // Only re-highlight when the plain text has actually changed externally
        // (e.g., Clear button, history load). Comparing plain strings avoids
        // re-triggering on every SwiftUI re-render.
        if textView.text != text {
            coordinator.isUpdating = true
            let maxLocation = (text as NSString).length
            textView.attributedText = SQLSyntaxHighlighter.highlight(
                text,
                keywordColor: keywordColor
            )
            textView.selectedRange = NSRange(location: maxLocation, length: 0)
            coordinator.isUpdating = false
        }
    }

    /// Creates the coordinator that serves as the `UITextViewDelegate`.
    ///
    /// - Returns: A new ``SQLTextEditorCoordinator`` instance configured
    ///   with the current bindings and keyword color.
    func makeCoordinator() -> SQLTextEditorCoordinator {
        SQLTextEditorCoordinator(
            text: $text,
            isFocused: $isFocused,
            keywordColor: keywordColor
        )
    }
}
