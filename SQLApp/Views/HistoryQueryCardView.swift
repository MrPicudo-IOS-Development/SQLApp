//
//  HistoryQueryCardView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import SwiftUI

/// A compact card displaying a preview of a previously executed SQL query.
///
/// Shows the first ~3 lines of the SQL text with syntax-highlighted keywords
/// (using ``SQLSyntaxHighlighter``).
/// Designed to be used inside a `NavigationLink` within ``HistoryView``.
struct HistoryQueryCardView: View {

    /// The history item whose SQL is previewed in this card.
    let item: QueryHistoryItem

    /// The color used to highlight SQL keywords, from the user's settings.
    let keywordColor: Color

    var body: some View {
        highlightedPreview
            .padding(.vertical, 4)
    }

    // MARK: - Highlighted Preview

    /// The first ~3 lines of the SQL text with syntax-highlighted keywords.
    private var highlightedPreview: some View {
        Text(attributedSQL)
            .font(.system(.caption, design: .monospaced))
            .lineLimit(3)
    }

    // MARK: - Helpers

    /// The SQL text converted to a SwiftUI `AttributedString` with keyword highlighting.
    ///
    /// Uses ``SQLSyntaxHighlighter/highlight(_:keywordColor:)`` to produce an
    /// `NSAttributedString`, then converts it to `AttributedString` for use in `Text`.
    private var attributedSQL: AttributedString {
        let keywordUIColor = HexColor.uiColor(from: HexColor.hex(from: keywordColor))
        let nsAttributed = SQLSyntaxHighlighter.highlight(item.sql, keywordColor: keywordUIColor)
        return (try? AttributedString(nsAttributed, including: \.uiKit)) ?? AttributedString(item.sql)
    }

}
