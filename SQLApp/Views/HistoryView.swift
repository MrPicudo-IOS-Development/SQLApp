//
//  HistoryView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 14/03/26.
//

import SwiftUI

/// Displays the combined History tab with two fixed sections that each
/// occupy half the screen: user-created tables on top and a persistent
/// query history log on the bottom.
///
/// Each section has its own independent scroll area, so the overall layout
/// stays fixed regardless of content size. This ensures consistent behavior
/// across all iPhone screen sizes.
///
/// The tables section reuses the same navigation pattern as the former
/// ``TableListView`` tab, navigating to ``TableDetailView`` on tap.
/// The history section shows syntax-highlighted SQL cards that navigate
/// to a read-only detail view with copy functionality.
///
/// Data is loaded automatically on appearance via `.task` and can be
/// manually refreshed using the toolbar button.
struct HistoryView: View {

    /// The ViewModel that manages the persistent query history.
    @Bindable var historyViewModel: HistoryViewModel

    /// The ViewModel that manages the table list and provides table detail data.
    @Bindable var tableBrowserViewModel: TableBrowserViewModel

    /// The settings ViewModel providing the keyword highlight color.
    let settingsViewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                titleHeader
                tablesSection
                historySection
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { tableName in
                TableDetailView(
                    tableName: tableName,
                    viewModel: tableBrowserViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
            .navigationDestination(for: UUID.self) { itemId in
                if let item = historyViewModel.history.first(where: { $0.id == itemId }) {
                    HistoryQueryDetailView(
                        item: item,
                        keywordColor: settingsViewModel.keywordColor
                    )
                }
            }
            .task {
                await tableBrowserViewModel.loadTables()
                await historyViewModel.loadHistory()
            }
        }
    }

    // MARK: - Title Header

    /// The inline title replacing the standard navigation title
    /// to prevent it from scrolling with the scroll view content.
    private var titleHeader: some View {
        Text("History")
            .font(.title3)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // MARK: - Tables Section

    /// The top half of the screen displaying all user-created tables.
    ///
    /// The section header stays fixed; only the scrollable content underneath moves.
    /// Uses a `ScrollView` instead of `List` to prevent scroll events from propagating
    /// to the `NavigationStack` title.
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if tableBrowserViewModel.tables.isEmpty {
                    ContentUnavailableView(
                        "No Tables",
                        systemImage: "tablecells.badge.ellipsis",
                        description: Text("Create tables using the SQL Editor tab")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(tableBrowserViewModel.tables, id: \.self) { tableName in
                                NavigationLink(value: tableName) {
                                    HStack {
                                        Label {
                                            Text(tableName)
                                        } icon: {
                                            Image(systemName: "tablecells")
                                                .foregroundStyle(settingsViewModel.keywordColor)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.quaternary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - History Section

    /// The bottom half of the screen displaying the persistent query history.
    ///
    /// Each history card is a `NavigationLink` that pushes ``HistoryQueryDetailView``.
    /// The scroll area is independent and confined to this half of the screen.
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Query History")

            Group {
                if let error = historyViewModel.historyError {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if historyViewModel.isLoadingHistory {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if historyViewModel.history.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Executed queries will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(historyViewModel.history) { item in
                                NavigationLink(value: item.id) {
                                    HStack {
                                        HistoryQueryCardView(
                                            item: item,
                                            keywordColor: settingsViewModel.keywordColor
                                        )
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.quaternary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Section Header

    /// A styled section header label consistent across both halves.
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
