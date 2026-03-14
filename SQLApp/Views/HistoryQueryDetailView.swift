//
//  HistoryQueryDetailView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import SwiftUI

/// A read-only detail view displaying the full SQL text of a history item
/// with syntax highlighting and a toolbar button to copy the query.
///
/// Navigated to from ``HistoryQueryCardView`` via `NavigationLink(value: UUID)`.
/// The SQL text supports native text selection via `.textSelection(.enabled)`.
struct HistoryQueryDetailView: View {

    /// The history item whose full SQL is displayed.
    let item: QueryHistoryItem

    /// The color used to highlight SQL keywords, from the user's settings.
    let keywordColor: Color

    /// Whether the "Copied" confirmation is currently visible.
    @State private var showCopiedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sqlContent
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Query Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            copyButton
        }
        .overlay(alignment: .bottom) {
            copiedBanner
        }
    }

    // MARK: - SQL Content

    /// The full SQL text with syntax-highlighted keywords and text selection enabled.
    private var sqlContent: some View {
        Text(attributedSQL)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Metadata

    /// A section showing the execution date.
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Label(formattedDate, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy Button

    /// A toolbar button that copies the raw SQL text to the system pasteboard.
    private var copyButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                UIPasteboard.general.string = item.sql
                withAnimation {
                    showCopiedConfirmation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showCopiedConfirmation = false
                    }
                }
            } label: {
                Image(systemName: "doc.on.doc")
            }
        }
    }

    // MARK: - Copied Banner

    /// A brief confirmation banner that appears after the user copies the query.
    private var copiedBanner: some View {
        Group {
            if showCopiedConfirmation {
                Text("Copied to clipboard")
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Helpers

    /// The SQL text converted to a SwiftUI `AttributedString` with keyword highlighting.
    private var attributedSQL: AttributedString {
        let keywordUIColor = HexColor.uiColor(from: HexColor.hex(from: keywordColor))
        let nsAttributed = SQLSyntaxHighlighter.highlight(item.sql, keywordColor: keywordUIColor)
        return (try? AttributedString(nsAttributed, including: \.uiKit)) ?? AttributedString(item.sql)
    }

    /// The execution date formatted in a readable style.
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.executedAt)
    }
}
