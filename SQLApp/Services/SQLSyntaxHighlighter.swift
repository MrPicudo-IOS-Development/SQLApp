import UIKit

/// Provides SQL syntax highlighting and auto-uppercasing for the editor.
///
/// This service operates on plain strings and `NSAttributedString` instances,
/// applying visual styling (color and font weight) to recognized SQLite keywords.
/// All methods are static and stateless — they produce new values without side effects.
///
/// Used by ``SQLTextEditorCoordinator`` to re-highlight the editor contents
/// after every text change and to auto-uppercase keywords as the user types.
///
/// This is a caseless enum used as a namespace to prevent instantiation.
enum SQLSyntaxHighlighter {

    /// The base monospaced font used for all non-keyword text in the SQL editor.
    ///
    /// Matches the `.system(.body, design: .monospaced)` font used in the original
    /// `TextEditor` implementation, using the system's preferred body text size.
    static let baseFont: UIFont = {
        let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
        return UIFont.monospacedSystemFont(ofSize: bodySize, weight: .regular)
    }()

    /// The semibold monospaced font applied to recognized SQL keywords.
    ///
    /// Uses the same point size as ``baseFont`` but with `.semibold` weight
    /// to visually distinguish keywords from identifiers and literals.
    static let keywordFont: UIFont = {
        let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
        return UIFont.monospacedSystemFont(ofSize: bodySize, weight: .semibold)
    }()

    /// Creates an `NSAttributedString` from SQL text with keywords highlighted.
    ///
    /// Scans the text for word tokens using a regex, checks each token against
    /// ``SQLKeywords/all``, and applies the keyword foreground color and semibold
    /// font to matches. Non-keyword text uses `UIColor.label` and regular weight.
    ///
    /// - Parameters:
    ///   - text: The plain SQL text to highlight.
    ///   - keywordColor: The `UIColor` to apply to recognized SQL keywords.
    /// - Returns: An `NSAttributedString` with syntax highlighting applied.
    static func highlight(_ text: String, keywordColor: UIColor) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: baseFont,
                .foregroundColor: UIColor.label
            ]
        )

        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        guard let regex = try? NSRegularExpression(pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b") else {
            return attributed
        }

        let matches = regex.matches(in: text, range: fullRange)

        for match in matches {
            let wordRange = match.range
            let word = nsString.substring(with: wordRange)

            if SQLKeywords.all.contains(word.uppercased()) {
                attributed.addAttributes(
                    [
                        .foregroundColor: keywordColor,
                        .font: keywordFont
                    ],
                    range: wordRange
                )
            }
        }

        return attributed
    }

    /// Auto-uppercases the word immediately before a boundary character if it is a SQL keyword.
    ///
    /// Called when the user types a word-boundary character (space, newline, tab,
    /// comma, semicolon, or parenthesis). Scans backward from the boundary to find
    /// the preceding word, checks it against ``SQLKeywords/all``, and replaces it
    /// with its uppercased form if it matches.
    ///
    /// - Parameters:
    ///   - text: The current full text of the editor, mutated in place if a keyword is found.
    ///   - boundaryIndex: The `String.Index` of the boundary character that triggered
    ///     the check (the character just typed).
    /// - Returns: The `NSRange` of the replaced word if a keyword was uppercased,
    ///   or `nil` if no replacement occurred.
    @discardableResult
    static func autoUppercaseLastKeyword(
        in text: inout String,
        boundaryIndex: String.Index
    ) -> NSRange? {
        guard boundaryIndex > text.startIndex else { return nil }

        let wordEnd = text.index(before: boundaryIndex)

        guard text[wordEnd].isLetter || text[wordEnd] == "_" else { return nil }

        var wordStart = wordEnd
        while wordStart > text.startIndex {
            let prev = text.index(before: wordStart)
            if text[prev].isLetter || text[prev].isNumber || text[prev] == "_" {
                wordStart = prev
            } else {
                break
            }
        }

        let wordRange = wordStart...wordEnd
        let word = String(text[wordRange])
        let uppercased = word.uppercased()

        guard SQLKeywords.all.contains(uppercased), word != uppercased else {
            return nil
        }

        text.replaceSubrange(wordRange, with: uppercased)
        let nsLocation = text.distance(from: text.startIndex, to: wordStart)
        return NSRange(location: nsLocation, length: uppercased.count)
    }

    /// The set of characters that act as word boundaries and trigger auto-uppercase.
    ///
    /// When any of these characters is typed, the coordinator checks whether
    /// the word immediately before it is a SQL keyword and uppercases it.
    static let boundaryCharacters: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: " \t\n,;()")
        return set
    }()

    /// Checks whether a given Unicode scalar is a word-boundary character.
    ///
    /// - Parameter scalar: The Unicode scalar to check.
    /// - Returns: `true` if the character is in ``boundaryCharacters``.
    static func isBoundaryCharacter(_ scalar: Unicode.Scalar) -> Bool {
        boundaryCharacters.contains(scalar)
    }
}
