//
//  TableDetailView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// Displays the schema and data of a specific database table.
///
/// Provides a segmented picker to switch between two views:
/// - **Structure**: A list of column definitions showing name, type,
///   primary key status, `NOT NULL` constraint, and default value.
/// - **Data**: A scrollable grid of the table's row data using ``ResultsTableView``.
///
/// Table details are loaded lazily when the view first appears via `.task`.
/// The view receives its data through ``TableBrowserViewModel``, which
/// delegates to the database service.
struct TableDetailView: View {

    /// The name of the table whose details are displayed.
    let tableName: String

    /// The ViewModel used to fetch table schema and data from the database.
    let viewModel: TableBrowserViewModel

    /// The settings ViewModel providing the accent color for column headers.
    let settingsViewModel: SettingsViewModel

    /// The table's column definitions, loaded asynchronously on appearance.
    @State private var tableInfo: TableInfo?

    /// The table's row data, loaded asynchronously on appearance.
    @State private var tableData: QueryResult?

    /// An error message if loading the table details failed.
    @State private var errorMessage: String?

    /// The currently selected detail tab (structure or data).
    @State private var selectedTab: DetailTab = .structure

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .padding()

            Group {
                switch selectedTab {
                case .structure:
                    structureView
                case .data:
                    dataView
                }
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle(tableName)
        .task {
            await loadDetails()
        }
    }

    // MARK: - Structure View

    /// Displays the table's column definitions as a list.
    ///
    /// Each row shows the column name and type, along with visual badges
    /// for primary key (orange key icon), `NOT NULL` constraint (red text),
    /// and default value (blue text).
    private var structureView: some View {
        Group {
            if let error = errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let info = tableInfo {
                List(info.columns) { column in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(column.name)
                                .font(.system(.body, design: .monospaced).bold())
                            Spacer()
                            Text(column.type)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            if column.isPrimaryKey {
                                Label("PK", systemImage: "key.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            if column.isNotNull {
                                Text("NOT NULL")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                            if let defaultVal = column.defaultValue {
                                Text("DEFAULT: \(defaultVal)")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                ProgressView()
            }
        }
    }

    // MARK: - Data View

    /// Displays the table's row data using the reusable ``ResultsTableView``.
    private var dataView: some View {
        Group {
            if let data = tableData {
                ResultsTableView(result: data, headerColor: settingsViewModel.keywordColor)
            } else {
                ProgressView()
            }
        }
    }

    // MARK: - Data Loading

    /// Loads both the table schema and row data from the database.
    ///
    /// Called once when the view first appears. On failure, sets ``errorMessage``
    /// to display an error state in the structure view.
    private func loadDetails() async {
        do {
            tableInfo = try await viewModel.getTableInfo(tableName)
            tableData = try await viewModel.getTableData(tableName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
