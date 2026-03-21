//
//  DatabaseView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import SwiftUI

/// Displays the Database tab with a scrollable list of table cards and a
/// "Query History" button at the bottom that navigates to a fullscreen history list.
///
/// Each table is shown as a card with an icon, name, column count, and row count
/// using ``TableCardView``. Tapping a card navigates to ``TableDetailView``.
///
/// The "Query History" button pushes ``QueryHistoryListView`` onto the navigation
/// stack, which automatically hides the tab bar.
struct DatabaseView: View {

    /// All possible navigation destinations within the Database tab.
    enum Destination: Hashable {
        case table(String)
        case queryHistory
        case queryDetail(UUID)
    }

    /// The ViewModel that manages the persistent query history.
    @Bindable var databaseViewModel: DatabaseViewModel

    /// The ViewModel that manages the table list and provides table detail data.
    @Bindable var tableBrowserViewModel: TableBrowserViewModel

    /// The settings ViewModel providing the keyword highlight color.
    let settingsViewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                titleHeader

                ScrollView {
                    VStack(spacing: 16) {
                        tablesSection
                        queryHistoryButton
                    }
                    .padding(.bottom, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .table(let tableName):
                    TableDetailView(
                        viewModel: TableDetailViewModel(
                            tableName: tableName,
                            databaseService: tableBrowserViewModel.databaseServiceForDetail
                        ),
                        settingsViewModel: settingsViewModel
                    )
                case .queryHistory:
                    QueryHistoryListView(
                        databaseViewModel: databaseViewModel,
                        keywordColor: settingsViewModel.selectedStyle.accentColor
                    )
                case .queryDetail(let itemId):
                    if let item = databaseViewModel.history.first(where: { $0.id == itemId }) {
                        HistoryQueryDetailView(
                            item: item,
                            keywordColor: settingsViewModel.selectedStyle.accentColor
                        )
                    }
                }
            }
            .task {
                await tableBrowserViewModel.loadTables()
                await tableBrowserViewModel.loadTableSummaries()
                await databaseViewModel.loadHistory()
            }
        }
    }

    // MARK: - Title Header

    /// The inline title replacing the standard navigation title
    /// to prevent it from scrolling with the scroll view content.
    private var titleHeader: some View {
        Text("Database")
            .font(.title3)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // MARK: - Tables Section

    /// The tables section showing a card for each user-created table.
    private var tablesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Tables")

            Group {
                if let error = tableBrowserViewModel.errorMessage {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if tableBrowserViewModel.isLoading {
                    ProgressView("Loading tables...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if tableBrowserViewModel.tableSummaries.isEmpty {
                    ContentUnavailableView(
                        "No Tables",
                        systemImage: "tablecells.badge.ellipsis",
                        description: Text("Create tables using the SQL Editor tab")
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(tableBrowserViewModel.tableSummaries) { summary in
                            NavigationLink(value: Destination.table(summary.name)) {
                                TableCardView(
                                    summary: summary,
                                    accentColor: settingsViewModel.selectedStyle.accentColor
                                )
                            }
                            .buttonStyle(.plain)
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Query History Button

    /// A navigation link styled as a button that pushes the fullscreen query history list.
    private var queryHistoryButton: some View {
        NavigationLink(value: Destination.queryHistory) {
            HStack {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.title3)
                    .foregroundStyle(settingsViewModel.selectedStyle.accentColor)
                    .frame(width: 36)
                Text("Query History")
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }

    // MARK: - Section Header

    /// A styled section header label.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.vertical, 12)
    }
}
