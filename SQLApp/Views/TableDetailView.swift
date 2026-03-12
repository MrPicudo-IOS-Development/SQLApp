import SwiftUI

struct TableDetailView: View {
    let tableName: String
    let viewModel: TableBrowserViewModel

    @State private var tableInfo: TableInfo?
    @State private var tableData: QueryResult?
    @State private var errorMessage: String?
    @State private var selectedTab: DetailTab = .structure

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
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

    private var dataView: some View {
        Group {
            if let data = tableData {
                ResultsTableView(result: data)
            } else {
                ProgressView()
            }
        }
    }

    // MARK: - Data Loading

    private func loadDetails() async {
        do {
            tableInfo = try await viewModel.getTableInfo(tableName)
            tableData = try await viewModel.getTableData(tableName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


