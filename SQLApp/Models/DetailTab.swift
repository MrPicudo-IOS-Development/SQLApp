//
//  DetailTab.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import Foundation

/// Defines the available tabs in the table detail view.
///
/// Used by ``TableDetailView`` to switch between viewing
/// a table's column schema and its row data.
enum DetailTab: String, CaseIterable {

    /// Displays the table's column definitions, types, and constraints.
    case structure = "Structure"

    /// Displays the table's row data in a scrollable grid.
    case data = "Data"
}
