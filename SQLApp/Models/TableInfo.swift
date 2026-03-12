import Foundation

struct TableInfo: Identifiable, Sendable {
    let id: String
    let name: String
    let columns: [ColumnInfo]
}
