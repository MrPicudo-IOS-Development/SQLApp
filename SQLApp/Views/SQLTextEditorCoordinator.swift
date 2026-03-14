//
//  SQLTextEditorCoordinator.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import UIKit
import SwiftUI

/// Coordinator that acts as the `UITextViewDelegate` for ``SQLTextEditorView``.
///
/// Bridges UIKit's `UITextView` delegate callbacks to SwiftUI's binding and
/// focus state mechanisms. Responsible for:
/// - Synchronizing text changes from UIKit back to the ViewModel's `String` binding.
/// - Auto-uppercasing SQL keywords when a word-boundary character is typed.
/// - Re-applying syntax highlighting after every text change while preserving cursor position.
/// - Communicating focus state (first responder status) back to SwiftUI via a `Binding<Bool>`.
///
/// Created and owned by ``SQLTextEditorView`` through the standard
/// `UIViewRepresentable` coordinator pattern.
final class SQLTextEditorCoordinator: NSObject, UITextViewDelegate {

    /// Binding to the plain SQL text string in the ViewModel.
    var text: Binding<String>

    /// Binding to the focus state, mirroring `@FocusState` behavior for UIKit views.
    var isFocused: Binding<Bool>

    /// The current keyword highlight color, updated when settings change.
    var keywordColor: UIColor

    /// Prevents re-entrant updates when the coordinator or `updateUIView` modifies
    /// the text view's `attributedText` (which would otherwise trigger `textViewDidChange`).
    var isUpdating = false

    /// Creates a new coordinator with the given bindings and keyword color.
    ///
    /// - Parameters:
    ///   - text: Binding to the ViewModel's `sqlText` property.
    ///   - isFocused: Binding to the view's focus tracking property.
    ///   - keywordColor: The `UIColor` for SQL keyword highlighting.
    init(text: Binding<String>, isFocused: Binding<Bool>, keywordColor: UIColor) {
        self.text = text
        self.isFocused = isFocused
        self.keywordColor = keywordColor
    }

    // MARK: - UITextViewDelegate

    /// Called after every text change in the text view.
    ///
    /// Performs three operations in sequence:
    /// 1. **Auto-uppercase**: If the last typed character is a word boundary,
    ///    checks the preceding word against ``SQLKeywords/all`` and uppercases it.
    /// 2. **Sync binding**: Updates the SwiftUI `text` binding with the current
    ///    plain text from the text view.
    /// 3. **Re-highlight**: Rebuilds the `NSAttributedString` with syntax highlighting
    ///    and applies it to the text view, preserving the cursor position.
    ///
    /// - Parameter textView: The `UITextView` whose text changed.
    func textViewDidChange(_ textView: UITextView) {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        var currentText = textView.text ?? ""
        var cursorOffset = textView.selectedRange.location

        // Step 1: Auto-uppercase the last keyword if a boundary was typed
        if let lastChar = currentText.last,
           let scalar = lastChar.unicodeScalars.first,
           SQLSyntaxHighlighter.isBoundaryCharacter(scalar) {

            let boundaryIndex = currentText.index(before: currentText.endIndex)
            SQLSyntaxHighlighter.autoUppercaseLastKeyword(
                in: &currentText,
                boundaryIndex: boundaryIndex
            )
        }

        // Step 2: Sync plain text to SwiftUI binding
        text.wrappedValue = currentText

        // Step 3: Re-highlight with cursor preservation
        cursorOffset = min(cursorOffset, (currentText as NSString).length)
        textView.attributedText = SQLSyntaxHighlighter.highlight(
            currentText,
            keywordColor: keywordColor
        )
        textView.selectedRange = NSRange(location: cursorOffset, length: 0)
    }

    /// Called when the text view becomes first responder (gains keyboard focus).
    ///
    /// Updates the `isFocused` binding to `true`, enabling the parent
    /// SwiftUI view to react to focus changes (e.g., showing the Clear button).
    ///
    /// - Parameter textView: The `UITextView` that gained focus.
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isFocused.wrappedValue {
            isFocused.wrappedValue = true
        }
    }

    /// Called when the text view resigns first responder (loses keyboard focus).
    ///
    /// Updates the `isFocused` binding to `false`.
    ///
    /// - Parameter textView: The `UITextView` that lost focus.
    func textViewDidEndEditing(_ textView: UITextView) {
        if isFocused.wrappedValue {
            isFocused.wrappedValue = false
        }
    }
}
