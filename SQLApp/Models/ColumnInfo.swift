import Foundation

struct ColumnInfo: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let type: String
    let isNotNull: Bool
    let isPrimaryKey: Bool
    let defaultValue: String?
}
