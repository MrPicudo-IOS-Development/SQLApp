//
//  QueryHistoryListView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 15/03/26.
//

import SwiftUI

/// A fullscreen view displaying the complete query history list.
///
/// Pushed onto the navigation stack from ``DatabaseView``, which automatically
/// hides the tab bar. Each query card navigates to ``HistoryQueryDetailView``
/// for a read-only view with copy functionality.
struct QueryHistoryListView: View {

    /// The ViewModel that manages the persistent query history.
    @Bindable var databaseViewModel: DatabaseViewModel

    /// The color used to highlight SQL keywords, from the user's settings.
    let keywordColor: Color

    var body: some View {
        Group {
            if databaseViewModel.history.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Executed queries will appear here")
                )
            } else {
                List(databaseViewModel.history) { item in
                    NavigationLink(value: DatabaseView.Destination.queryDetail(item.id)) {
                        HistoryQueryCardView(item: item, keywordColor: keywordColor)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Query History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
