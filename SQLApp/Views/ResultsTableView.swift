//
//  ResultsTableView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// A reusable view that displays SQL query results in a scrollable grid format.
///
/// Renders column headers with bold monospaced font in the user-chosen keyword
/// color, followed by data rows with alternating background colors for readability.
/// Supports both horizontal and vertical scrolling to accommodate wide result sets.
///
/// Used by both ``QueryEditorView`` (for `SELECT` results) and ``TableDetailView``
/// (for table data browsing), following the DRY principle.
///
/// Displays a "No Rows" empty state when the query returned zero rows.
struct ResultsTableView: View {

    /// The query result data to display, containing column names and row values.
    let result: QueryResult

    /// The accent color used for column header text, provided by ``SettingsViewModel``.
    var headerColor: Color = .secondary

    /// Horizontal padding applied to each cell.
    private let cellHPadding: CGFloat = 12

    /// Minimum column width — sized to comfortably fit ~4 digits plus cell padding.
    private let minColumnWidth: CGFloat = 55

    /// Font used for header cells.
    private let headerFont: Font = .system(.caption, design: .monospaced).bold()

    /// Font used for data cells.
    private let dataFont: Font = .system(.caption, design: .monospaced)

    // MARK: - Column Widths

    /// Pre-computed fixed width for each column index, based on the widest
    /// content across the header and every data row. This guarantees that the
    /// sticky header and the scrollable data rows stay perfectly aligned.
    private var columnWidths: [CGFloat] {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
        ]
        return result.columns.indices.map { colIndex in
            // Measure header text (bold has same advance in monospaced)
            let headerWidth = (result.columns[colIndex] as NSString)
                .size(withAttributes: attributes).width
            // Measure every data cell in this column
            let maxDataWidth = result.rows.reduce(CGFloat(0)) { current, row in
                guard colIndex < row.count else { return current }
                let w = (row[colIndex] as NSString).size(withAttributes: attributes).width
                return max(current, w)
            }
            // Add horizontal padding on both sides, enforce minimum
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
                        headerRow(widths: widths)
                        ScrollView(.vertical) {
                            dataRows(widths: widths)
                        }
                    }
                    .frame(
                        minWidth: fitsInView ? geo.size.width : nil,
                        alignment: fitsInView ? .center : .leading
                    )
                }
            }
        }
    }

    // MARK: - Header Row

    private func headerRow(widths: [CGFloat]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(result.columns.enumerated()), id: \.offset) { colIndex, column in
                Text(column)
                    .font(headerFont)
                    .foregroundStyle(headerColor)
                    .padding(.horizontal, cellHPadding)
                    .padding(.vertical, 8)
                    .frame(width: widths[colIndex], alignment: .leading)
                    .background(Color(.systemGray5))
            }
        }
    }

    // MARK: - Data Rows

    private func dataRows(widths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                        Text(value)
                            .font(dataFont)
                            .padding(.horizontal, cellHPadding)
                            .padding(.vertical, 6)
                            .frame(width: widths[colIndex], alignment: .leading)
                            .background(rowIndex.isMultiple(of: 2) ? Color.clear : Color(.systemGray6))
                    }
                }
            }
        }
    }
}
