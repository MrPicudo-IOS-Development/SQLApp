//
//  ExercisesView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 15/03/26.
//

import SwiftUI

/// The Exercises tab showing a vertical list of exercise block cards.
///
/// On appear the view triggers table seeding for every block via ``ExercisesViewModel``.
/// Cards whose tables are still being seeded show a loading indicator and block
/// navigation, preventing the user from entering a block before its tables exist.
///
/// All exercise queries run against `app_database.sqlite`, which is completely
/// isolated from the user's sandbox database.
struct ExercisesView: View {
    
    /// Navigation destinations within the Exercises tab.
    enum Destination: Hashable {
        case exerciseDetail(ExerciseBlock)
        case blockResults(ExerciseBlock, [ExerciseAttemptRecord])
    }
    
    /// The ViewModel for the SQL editor, connected to the app database.
    @Bindable var queryEditorViewModel: QueryEditorViewModel
    
    /// The settings ViewModel providing the keyword highlight color.
    let settingsViewModel: SettingsViewModel
    
    /// Manages per-block table seeding state and expected results.
    @Bindable var exercisesViewModel: ExercisesViewModel
    
    // MARK: - Exercise Blocks
    
    /// All exercise blocks, sourced from the centralized ``ExerciseCatalog``.
    private let exerciseBlocks = ExerciseCatalog.exerciseBlocks
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: settingsViewModel.selectedStyle.cardSpacing) {
                    ForEach(exerciseBlocks) { block in
                        blockCard(for: block)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Query practice")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .exerciseDetail(let block):
                    ExerciseDetailView(
                        viewModel: exercisesViewModel.detailViewModel(
                            for: block,
                            queryEditorViewModel: queryEditorViewModel
                        ),
                        settingsViewModel: settingsViewModel
                    )
                case .blockResults(let block, let attempts):
                    BlockResultsView(
                        block: block,
                        attempts: attempts,
                        accentColor: settingsViewModel.selectedStyle.accentColor,
                        onDismiss: { navigationPath = NavigationPath() }
                    )
                }
            }
            .task {
                // Load persisted scores first, then seed tables.
                await exercisesViewModel.loadScoresIfNeeded()
                for block in exerciseBlocks {
                    await exercisesViewModel.seedTablesIfNeeded(for: block)
                }
            }
        }
    }
    
    // MARK: - Card Builder
    
    @ViewBuilder
    private func blockCard(for block: ExerciseBlock) -> some View {
        let seeding = exercisesViewModel.isSeeding(block)
        let seeded = exercisesViewModel.isSeeded(block)
        let error = exercisesViewModel.seedingError(for: block)
        
        if seeded && error == nil {
            // Tables ready — navigation allowed
            NavigationLink(value: Destination.exerciseDetail(block)) {
                StyledExerciseBlockCardView(
                    block: block,
                    style: settingsViewModel.selectedStyle,
                    bestStars: exercisesViewModel.bestStars(for: block)
                )
            }
            .buttonStyle(.plain)
        } else {
            // Seeding in progress or error — navigation blocked
            StyledExerciseBlockCardView(
                block: block,
                style: settingsViewModel.selectedStyle,
                bestStars: exercisesViewModel.bestStars(for: block)
            )
            .overlay {
                if seeding {
                    seedingOverlay
                } else if let error {
                    errorOverlay(message: error)
                }
            }
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Overlays
    
    private var seedingOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.primary)
                Text("Preparing tables…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(8)
                .multilineTextAlignment(.center)
        }
    }
}
