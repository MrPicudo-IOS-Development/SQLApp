//
//  StyledResultsTableView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 20/03/26.
//

import SwiftUI

/// A style-aware results table that renders SQL query results with a visual
/// design matching the selected ``AppStyle``.
///
/// Each of the 5 styles produces a structurally distinct table:
/// - **Vibrant**: Bold colored header background, thick accent separators, high-contrast alternating rows
/// - **Glassmorphism**: Frosted translucent header, subtle 1px borders on cells, semi-transparent rows
/// - **Minimalism**: No backgrounds or alternating colors — clean horizontal lines, generous whitespace
/// - **Dark Mode**: True OLED black, subtle glow on headers, dark separators, neon accent text
/// - **Bento Grid**: Each cell as a bordered module with grid gaps, accent left-border on header
///
/// Design guidelines from the UI UX Pro Max skill.
struct StyledResultsTableView: View {

    /// The query result data to display.
    let result: QueryResult

    /// The visual style to apply.
    let style: AppStyle

    /// Horizontal padding inside each cell.
    private let cellHPadding: CGFloat = 12

    /// Minimum column width.
    private let minColumnWidth: CGFloat = 55

    /// Pre-computed column widths based on content.
    private var columnWidths: [CGFloat] {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
        ]
        return result.columns.indices.map { colIndex in
            let headerWidth = (result.columns[colIndex] as NSString)
                .size(withAttributes: attributes).width
            let maxDataWidth = result.rows.reduce(CGFloat(0)) { current, row in
                guard colIndex < row.count else { return current }
                let w = (row[colIndex] as NSString).size(withAttributes: attributes).width
                return max(current, w)
            }
            return max(ceil(max(headerWidth, maxDataWidth)) + cellHPadding * 2, minColumnWidth)
        }
    }

    var body: some View {
        if result.isEmpty {
            ContentUnavailableView(
                "No Rows",
                systemImage: "tablecells",
                description: Text("Query returned 0 rows")
            )
        } else {
            let widths = columnWidths
            let tableWidth = widths.reduce(0, +)
            GeometryReader { geo in
                let fitsInView = tableWidth <= geo.size.width
                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        styledHeader(widths: widths)
                        ScrollView(.vertical) {
                            styledDataRows(widths: widths)
                        }
                    }
                    .frame(
                        minWidth: fitsInView ? geo.size.width : nil,
                        alignment: fitsInView ? .center : .leading
                    )
                }
            }
            .background(style.tableBackground)
            .clipShape(RoundedRectangle(cornerRadius: style.tableCornerRadius))
            .overlay(tableOverlay)
        }
    }

    // MARK: - Table Overlay (border)

    @ViewBuilder
    private var tableOverlay: some View {
        switch style {
        case .glassmorphism:
            RoundedRectangle(cornerRadius: style.tableCornerRadius)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        case .bentoGrid:
            RoundedRectangle(cornerRadius: style.tableCornerRadius)
                .stroke(style.tableBorderColor, lineWidth: 1)
        case .minimalism:
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        default:
            EmptyView()
        }
    }

    // MARK: - Header Row

    @ViewBuilder
    private func styledHeader(widths: [CGFloat]) -> some View {
        switch style {
        case .vibrant:
            vibrantHeader(widths: widths)
        case .glassmorphism:
            glassmorphismHeader(widths: widths)
        case .minimalism:
            minimalismHeader(widths: widths)
        case .darkMode:
            darkModeHeader(widths: widths)
        case .bentoGrid:
            bentoGridHeader(widths: widths)
        }
    }

    // MARK: Vibrant Header
    /// Bold green background, dark text, thick bottom border.
    private func vibrantHeader(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                    Text(column.uppercased())
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.tableHeaderText)
                        .padding(.horizontal, cellHPadding)
                        .padding(.vertical, 10)
                        .frame(width: widths[colIndex], alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.tableHeaderBackground)

            // Thick accent separator
            Rectangle()
                .fill(Color(hex: 0x22C55E))
                .frame(height: 3)
        }
    }

    // MARK: Glassmorphism Header
    /// Frosted translucent background, light text, subtle bottom border.
    private func glassmorphismHeader(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                    Text(column)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.tableHeaderText)
                        .padding(.horizontal, cellHPadding)
                        .padding(.vertical, 10)
                        .frame(width: widths[colIndex], alignment: .leading)
                        .overlay(alignment: .trailing) {
                            if colIndex < result.columns.count - 1 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 1)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }

    // MARK: Minimalism Header
    /// No background, black text, single clean bottom line.
    private func minimalismHeader(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                    Text(column)
                        .font(.system(.caption2, design: .default).weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(style.tableHeaderText)
                        .padding(.horizontal, cellHPadding)
                        .padding(.vertical, 10)
                        .frame(width: widths[colIndex], alignment: .leading)
                }
            }

            Rectangle()
                .fill(Color(hex: 0x1E293B))
                .frame(height: 1.5)
        }
    }

    // MARK: Dark Mode Header
    /// Pure black background, neon glow text, thin separator.
    private func darkModeHeader(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                    Text(column)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.tableHeaderText)
                        .shadow(color: style.tableHeaderText.opacity(0.5), radius: 4, x: 0, y: 0)
                        .padding(.horizontal, cellHPadding)
                        .padding(.vertical, 10)
                        .frame(width: widths[colIndex], alignment: .leading)
                }
            }
            .background(style.tableHeaderBackground)

            Rectangle()
                .fill(style.tableHeaderText.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: Bento Grid Header
    /// Accent left border stripe, dark background, red accent text, cell borders.
    private func bentoGridHeader(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                    Text(column)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(style.tableHeaderText)
                        .padding(.horizontal, cellHPadding)
                        .padding(.vertical, 8)
                        .frame(width: widths[colIndex], alignment: .leading)
                        .overlay(alignment: .trailing) {
                            if colIndex < result.columns.count - 1 {
                                Rectangle()
                                    .fill(style.tableBorderColor)
                                    .frame(width: 1)
                            }
                        }
                }
            }
            .background(style.tableHeaderBackground)
            .overlay(alignment: .leading) {
                // Accent left stripe as overlay so it doesn't affect height
                Rectangle()
                    .fill(Color(hex: 0xEF4444))
                    .frame(width: 3)
            }

            Rectangle()
                .fill(style.tableBorderColor)
                .frame(height: 1)
        }
    }

    // MARK: - Data Rows

    @ViewBuilder
    private func styledDataRows(widths: [CGFloat]) -> some View {
        switch style {
        case .vibrant:
            vibrantDataRows(widths: widths)
        case .glassmorphism:
            glassmorphismDataRows(widths: widths)
        case .minimalism:
            minimalismDataRows(widths: widths)
        case .darkMode:
            darkModeDataRows(widths: widths)
        case .bentoGrid:
            bentoGridDataRows(widths: widths)
        }
    }

    // MARK: Vibrant Data Rows
    /// High-contrast alternating dark rows with accent-tinted separators.
    private func vibrantDataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(style.tableDataText)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 8)
                            .frame(width: widths[colIndex], alignment: .leading)
                    }
                }
                .background(
                    rowIndex.isMultiple(of: 2)
                        ? style.tableRowEvenBackground
                        : style.tableRowOddBackground
                )

                if rowIndex < result.rows.count - 1 {
                    Rectangle()
                        .fill(style.tableSeparatorColor)
                        .frame(height: 1)
                }
            }
        }
    }

    // MARK: Glassmorphism Data Rows
    /// Semi-transparent rows with subtle cell borders.
    private func glassmorphismDataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(style.tableDataText)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 8)
                            .frame(width: widths[colIndex], alignment: .leading)
                            .overlay(alignment: .trailing) {
                                if colIndex < row.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 1)
                                }
                            }
                    }
                }
                .background(
                    rowIndex.isMultiple(of: 2)
                        ? style.tableRowEvenBackground
                        : style.tableRowOddBackground
                )

                if rowIndex < result.rows.count - 1 {
                    Rectangle()
                        .fill(style.tableSeparatorColor)
                        .frame(height: 1)
                }
            }
        }
    }

    // MARK: Minimalism Data Rows
    /// No alternating colors, clean lines only, generous padding.
    private func minimalismDataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(.system(.caption, design: .default))
                            .foregroundStyle(style.tableDataText)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 10)
                            .frame(width: widths[colIndex], alignment: .leading)
                    }
                }

                if rowIndex < result.rows.count - 1 {
                    Rectangle()
                        .fill(style.tableSeparatorColor)
                        .frame(height: 0.5)
                }
            }

            // Bottom line to close the table
            Rectangle()
                .fill(Color(hex: 0x1E293B))
                .frame(height: 1.5)
        }
    }

    // MARK: Dark Mode Data Rows
    /// OLED-optimized with subtle dark alternation and thin separators.
    private func darkModeDataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(style.tableDataText)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 8)
                            .frame(width: widths[colIndex], alignment: .leading)
                    }
                }
                .background(
                    rowIndex.isMultiple(of: 2)
                        ? style.tableRowEvenBackground
                        : style.tableRowOddBackground
                )

                if rowIndex < result.rows.count - 1 {
                    Rectangle()
                        .fill(style.tableSeparatorColor)
                        .frame(height: 1)
                }
            }
        }
    }

    // MARK: Bento Grid Data Rows
    /// Modular cells with visible borders forming a grid, accent left stripe.
    private func bentoGridDataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(style.tableDataText)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 8)
                            .frame(width: widths[colIndex], alignment: .leading)
                            .overlay(alignment: .trailing) {
                                if colIndex < row.count - 1 {
                                    Rectangle()
                                        .fill(style.tableBorderColor)
                                        .frame(width: 1)
                                }
                            }
                    }
                }
                .background(
                    rowIndex.isMultiple(of: 2)
                        ? style.tableRowEvenBackground
                        : style.tableRowOddBackground
                )
                .overlay(alignment: .leading) {
                    // Accent left stripe as overlay
                    Rectangle()
                        .fill(
                            Color(hex: 0xEF4444).opacity(
                                rowIndex.isMultiple(of: 2) ? 0.3 : 0.15
                            )
                        )
                        .frame(width: 3)
                }

                Rectangle()
                    .fill(style.tableBorderColor)
                    .frame(height: 1)
            }
        }
    }
}
// MARK: - Previews

private let previewResult = QueryResult(
    columns: ["title", "release_year", "genre", "metacritic_score"],
    rows: [
        ["Breath of the Wild", "2017", "Action-Adventure", "97"],
        ["Grand Theft Auto V", "2013", "Action-Adventure", "97"],
        ["Elden Ring", "2022", "RPG", "96"],
        ["Baldur's Gate 3", "2023", "RPG", "96"],
        ["Skyrim", "2011", "RPG", "94"],
    ]
)

#Preview("Vibrant") {
    StyledResultsTableView(result: previewResult, style: .vibrant)
        .frame(height: 200)
        .padding()
}

#Preview("Glassmorphism") {
    StyledResultsTableView(result: previewResult, style: .glassmorphism)
        .frame(height: 200)
        .padding()
}

#Preview("Minimalism") {
    StyledResultsTableView(result: previewResult, style: .minimalism)
        .frame(height: 200)
        .padding()
}

#Preview("Dark Mode") {
    StyledResultsTableView(result: previewResult, style: .darkMode)
        .frame(height: 200)
        .padding()
}

#Preview("Bento Grid") {
    StyledResultsTableView(result: previewResult, style: .bentoGrid)
        .frame(height: 200)
        .padding()
}

