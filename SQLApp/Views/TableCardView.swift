//
//  TableCardView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 15/03/26.
//

import SwiftUI

/// A reusable card displaying a table summary with an icon, name, column count,
/// and row count. Designed to be used inside a `NavigationLink` within ``DatabaseView``.
struct TableCardView: View {

    /// The summary data for the table to display.
    let summary: TableSummary

    /// The accent color applied to the table icon.
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tablecells")
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("\(summary.columnCount) columns · \(summary.rowCount) rows")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
