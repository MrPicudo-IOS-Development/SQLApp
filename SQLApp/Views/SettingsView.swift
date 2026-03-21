//
//  SettingsView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 10/03/26.
//

import SwiftUI

/// The settings screen where users can customize the app's visual style.
///
/// Provides a horizontal style picker with 5 options (Vibrant, Glassmorphism,
/// Minimalism, Dark Mode, Bento Grid). Below the picker, three live preview
/// components show how the selected style looks on:
/// - A non-editable SQL editor preview
/// - A results table with sample Videogames data
/// - An exercise block card
///
/// Also includes pinned table display settings.
struct SettingsView: View {

    /// The ViewModel that manages settings persistence and state.
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    pinnedTablesSection
                    stylePickerSection
                    previewSection
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
        }
    }

    // MARK: - Pinned Tables Section

    /// Settings for how pinned tables are displayed in the SQL editor.
    private var pinnedTablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pinned Tables", systemImage: "pin")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 0) {
                // Display mode picker
                HStack {
                    Text("Display Mode")
                    Spacer()
                    Picker("", selection: $viewModel.pinnedTableDisplayMode) {
                        ForEach(PinnedTableDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if viewModel.pinnedTableDisplayMode == .data {
                    Divider()
                        .padding(.leading, 16)

                    // Row limit picker
                    HStack {
                        Text("Row Limit")
                        Spacer()
                        Picker("", selection: $viewModel.pinnedTableRowLimit) {
                            ForEach(SettingsViewModel.rowLimitOptions, id: \.self) { limit in
                                Text("\(limit) rows").tag(limit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(viewModel.pinnedTableDisplayMode == .data
                 ? "Choose how pinned tables are displayed and the maximum number of rows shown for each table."
                 : "Choose whether pinned tables in the SQL Editor show row data or column structure.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Style Picker Section

    /// Horizontal scroll of 5 style options with selection state.
    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("App Style", systemImage: "paintpalette")
                .font(.title3)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppStyle.allCases) { style in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                viewModel.selectedStyle = style
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: style.icon)
                                    .font(.title2)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        viewModel.selectedStyle == style
                                            ? style.accentColor.opacity(0.2)
                                            : Color(.tertiarySystemGroupedBackground)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                viewModel.selectedStyle == style
                                                    ? style.accentColor
                                                    : .clear,
                                                lineWidth: 2
                                            )
                                    )

                                Text(style.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(
                                viewModel.selectedStyle == style
                                    ? style.accentColor
                                    : .secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Style description card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedStyle.name)
                        .font(.headline)
                    Text(viewModel.selectedStyle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Preview Section

    /// Live preview showing how the selected style looks on app components.
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Preview", systemImage: "eye")
                .font(.title3)
                .fontWeight(.bold)

            sqlEditorPreview
            resultsTablePreview
            exerciseBlockPreview
        }
    }

    // MARK: - SQL Editor Preview

    /// A non-editable terminal-style SQL editor preview using the selected style's colors.
    private var sqlEditorPreview: some View {
        let style = viewModel.selectedStyle

        return VStack(spacing: 0) {
            // Terminal title bar
            HStack {
                Circle().fill(.red).frame(width: 10, height: 10)
                Circle().fill(.yellow).frame(width: 10, height: 10)
                Circle().fill(.green).frame(width: 10, height: 10)
                Spacer()
                Text("preview.sql")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(style.editorSecondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.editorTitleBar)

            // Syntax-highlighted SQL code
            Text(highlightedSQL(for: style))
                .font(.system(size: 13, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(style.editorBackground)

            // Mock control bar with Run button
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Run")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(style.runButtonTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(style.runButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("5 rows returned")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(style.editorSecondaryText)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.editorTitleBar)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Results Table Preview

    /// The VideoGames table with a styled title header, as it would appear in an exercise.
    private var resultsTablePreview: some View {
        let style = viewModel.selectedStyle

        return VStack(alignment: .leading, spacing: 0) {
            // Table title header — matches the exercise table preview pattern
            HStack(spacing: 8) {
                Image(systemName: "tablecells")
                    .font(.caption.bold())
                    .foregroundStyle(style.accentColor)
                Text("VideoGames")
                    .font(.headline)
                    .foregroundStyle(style.accentColor)
                Spacer()
                Text("\(Self.sampleVideoGamesTable.rowCount) rows")
                    .font(.caption)
                    .foregroundStyle(style.editorSecondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.editorTitleBar)

            StyledResultsTableView(
                result: Self.sampleVideoGamesTable,
                style: style
            )
        }
        .frame(height: 240)
        // Title bar color behind everything so the rounded corner wedges
        // between the title header and the table header row blend seamlessly.
        .background(style.editorTitleBar)
        .clipShape(RoundedRectangle(cornerRadius: style.tableCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: style.tableCornerRadius)
                .stroke(style.tableBorderColor, lineWidth: style == .glassmorphism || style == .bentoGrid || style == .minimalism ? 1 : 0)
        )
    }

    // MARK: - Exercise Block Card Preview

    /// A mock exercise block card showing how the selected style looks.
    private var exerciseBlockPreview: some View {
        StyledExerciseBlockCardView(
            block: Self.sampleExerciseBlock,
            style: viewModel.selectedStyle,
            bestStars: 4
        )
    }

    // MARK: - SQL Highlighting

    /// Sample SQL text for the editor preview.
    private static let previewSQL = """
        SELECT title, genre, metacritic_score
        FROM VideoGames
        WHERE release_year >= 2020
        ORDER BY metacritic_score DESC
        LIMIT 5;
        """

    /// Builds an `AttributedString` with SQL keywords highlighted
    /// using the given style's keyword color.
    private func highlightedSQL(for style: AppStyle) -> AttributedString {
        let plain = Self.previewSQL
        var result = AttributedString()
        let keywordFont = Font.system(size: 13, weight: .semibold, design: .monospaced)
        let regularFont = Font.system(size: 13, weight: .regular, design: .monospaced)
        let keywordColor = style.editorKeywordColor
        let textColor = style.editorTextColor

        guard let regex = try? NSRegularExpression(
            pattern: "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b"
        ) else {
            return AttributedString(plain)
        }

        let nsString = plain as NSString
        let matches = regex.matches(
            in: plain,
            range: NSRange(location: 0, length: nsString.length)
        )

        var cursor = plain.startIndex
        for match in matches {
            guard let matchRange = Range(match.range, in: plain) else { continue }

            if cursor < matchRange.lowerBound {
                var gap = AttributedString(plain[cursor..<matchRange.lowerBound])
                gap.foregroundColor = textColor
                gap.font = regularFont
                result.append(gap)
            }

            let word = String(plain[matchRange]).uppercased()
            var segment = AttributedString(plain[matchRange])
            if SQLKeywords.all.contains(word) {
                segment.foregroundColor = keywordColor
                segment.font = keywordFont
            } else {
                segment.foregroundColor = textColor
                segment.font = regularFont
            }
            result.append(segment)
            cursor = matchRange.upperBound
        }

        if cursor < plain.endIndex {
            var tail = AttributedString(plain[cursor..<plain.endIndex])
            tail.foregroundColor = textColor
            tail.font = regularFont
            result.append(tail)
        }

        return result
    }

    // MARK: - Sample Data

    /// The full VideoGames table as it appears in the app's exercise database.
    /// Shows a representative subset of columns for the preview.
    private static let sampleVideoGamesTable = QueryResult(
        columns: ["title", "release_year", "genre", "metacritic_score", "copies_sold_million"],
        rows: [
            ["Breath of the Wild", "2017", "Action-Adventure", "97", "31.15"],
            ["Tears of the Kingdom", "2023", "Action-Adventure", "96", "20.80"],
            ["Grand Theft Auto V", "2013", "Action-Adventure", "97", "200.00"],
            ["Red Dead Redemption 2", "2018", "Action-Adventure", "97", "64.00"],
            ["The Witcher 3", "2015", "RPG", "93", "50.00"],
            ["Cyberpunk 2077", "2020", "RPG", "86", "30.00"],
            ["Elden Ring", "2022", "RPG", "96", "25.00"],
            ["Dark Souls III", "2016", "RPG", "89", "10.00"],
            ["Sekiro", "2019", "Action-Adventure", "91", "10.00"],
            ["The Last of Us Part II", "2020", "Action-Adventure", "93", "10.00"],
            ["Uncharted 4", "2016", "Action-Adventure", "93", "16.00"],
            ["Skyrim", "2011", "RPG", "94", "60.00"],
            ["God of War Ragnarök", "2022", "Action-Adventure", "94", "15.00"],
            ["God of War (2018)", "2018", "Action-Adventure", "94", "23.00"],
            ["Baldur's Gate 3", "2023", "RPG", "96", "15.00"],
            ["Hades", "2020", "Roguelike", "93", "6.00"],
            ["RE4 Remake", "2023", "Horror", "93", "7.50"],
            ["Monster Hunter: World", "2018", "RPG", "90", "21.00"],
            ["Spider-Man", "2018", "Action-Adventure", "87", "33.00"],
            ["Spider-Man 2", "2023", "Action-Adventure", "90", "11.00"],
            ["Hollow Knight", "2017", "Metroidvania", "87", "5.00"],
            ["Devil May Cry 5", "2019", "Action-Adventure", "88", "7.00"],
            ["Bloodborne", "2015", "RPG", "92", "8.00"],
        ]
    )

    /// Mock exercise block for the card preview.
    private static let sampleExerciseBlock = ExerciseBlock(
        imageName: "Videogames",
        sqlKeywords: ["INNER JOIN", "LEFT JOIN", "ON"],
        summary: "Query videogame data using joins to combine tables for deeper analysis.",
        tableNames: ["VideoGames"],
        jsonFileName: "preview",
        exercises: []
    )
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
