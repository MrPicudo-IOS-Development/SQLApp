import Foundation

/// Contains the complete set of SQLite reserved keywords used for
/// syntax highlighting and auto-uppercasing in the SQL editor.
///
/// The keyword list is sourced from the official SQLite documentation
/// at [sqlite.org/lang_keywords.html](https://www.sqlite.org/lang_keywords.html).
/// All keywords are stored in uppercase for case-insensitive matching
/// (callers should uppercase their input before checking membership).
///
/// This is a caseless enum used as a namespace to prevent instantiation.
enum SQLKeywords {

    /// The full set of SQLite reserved words, stored in uppercase.
    ///
    /// Provides O(1) lookup for keyword detection. Used by
    /// ``SQLSyntaxHighlighter`` to identify tokens that should receive
    /// keyword styling (color and weight) and by the auto-uppercase
    /// logic to transform recognized keywords to their canonical form.
    static let all: Set<String> = [
        "ABORT", "ACTION", "ADD", "AFTER", "ALL", "ALTER", "ALWAYS",
        "ANALYZE", "AND", "AS", "ASC", "ATTACH", "AUTOINCREMENT",
        "BEFORE", "BEGIN", "BETWEEN", "BY",
        "CASCADE", "CASE", "CAST", "CHECK", "COLLATE", "COLUMN",
        "COMMIT", "CONFLICT", "CONSTRAINT", "CREATE", "CROSS",
        "CURRENT", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP",
        "DATABASE", "DEFAULT", "DEFERRABLE", "DEFERRED", "DELETE",
        "DESC", "DETACH", "DISTINCT", "DO", "DROP",
        "EACH", "ELSE", "END", "ESCAPE", "EXCEPT", "EXCLUDE",
        "EXCLUSIVE", "EXISTS", "EXPLAIN",
        "FAIL", "FILTER", "FIRST", "FOLLOWING", "FOR", "FOREIGN",
        "FROM", "FULL",
        "GENERATED", "GLOB", "GROUP", "GROUPS",
        "HAVING",
        "IF", "IGNORE", "IMMEDIATE", "IN", "INDEX", "INDEXED",
        "INITIALLY", "INNER", "INSERT", "INSTEAD", "INTEGER",
        "INTERSECT", "INTO", "IS", "ISNULL",
        "JOIN",
        "KEY",
        "LAST", "LEFT", "LIKE", "LIMIT",
        "MATCH", "MATERIALIZED",
        "NATURAL", "NO", "NOT", "NOTHING", "NOTNULL", "NULL", "NULLS",
        "OF", "OFFSET", "ON", "OR", "ORDER", "OTHERS", "OUTER", "OVER",
        "PARTITION", "PLAN", "PRAGMA", "PRECEDING", "PRIMARY",
        "QUERY",
        "RAISE", "RANGE", "RECURSIVE", "REFERENCES", "REGEXP",
        "REINDEX", "RELEASE", "RENAME", "REPLACE", "RESTRICT",
        "RETURNING", "RIGHT", "ROLLBACK", "ROW", "ROWS",
        "SAVEPOINT", "SELECT", "SET",
        "TABLE", "TEMP", "TEMPORARY", "TEXT", "THEN", "TIES", "TO",
        "TRANSACTION", "TRIGGER",
        "UNBOUNDED", "UNION", "UNIQUE", "UPDATE", "USING",
        "VACUUM", "VALUES", "VIEW", "VIRTUAL",
        "WHEN", "WHERE", "WINDOW", "WITH", "WITHOUT"
    ]
}
