import Foundation

struct QueryResult: Sendable {
    let columns: [String]
    let rows: [[String]]

    var isEmpty: Bool { rows.isEmpty }
    var rowCount: Int { rows.count }
    var columnCount: Int { columns.count }
}
