import SwiftUI

struct ResultsTableView: View {
    let result: QueryResult

    var body: some View {
        if result.isEmpty {
            ContentUnavailableView(
                "No Rows",
                systemImage: "tablecells",
                description: Text("Query returned 0 rows")
            )
        } else {
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                    // Header row
                    GridRow {
                        ForEach(result.columns, id: \.self) { column in
                            Text(column)
                                .font(.system(.caption, design: .monospaced).bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 80, alignment: .leading)
                                .background(Color(.systemGray5))
                        }
                    }

                    Divider()

                    // Data rows
                    ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                        GridRow {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                                Text(value)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .frame(minWidth: 80, alignment: .leading)
                            }
                        }
                        .background(index.isMultiple(of: 2) ? Color.clear : Color(.systemGray6))
                    }
                }
            }
        }
    }
}
