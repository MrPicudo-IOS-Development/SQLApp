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
/// Business logic and data loading are handled by ``TableDetailViewModel``.
struct TableDetailView: View {

    /// The ViewModel that manages table schema and data loading.
    @Bindable var viewModel: TableDetailViewModel

    /// The settings ViewModel providing the accent color for column headers.
    let settingsViewModel: SettingsViewModel

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
        .navigationTitle(viewModel.tableName)
        .task {
            await viewModel.loadDetails()
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
            if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let info = viewModel.tableInfo {
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
            if let data = viewModel.tableData {
                ResultsTableView(result: data, headerColor: settingsViewModel.keywordColor)
            } else {
                ProgressView()
            }
        }
    }

}
