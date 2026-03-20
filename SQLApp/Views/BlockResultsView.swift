//
//  BlockResultsView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 18/03/26.
//

import SwiftUI

/// Summary screen shown after the user completes all exercises in a block.
///
/// Displays:
/// - A row of 5 stars, one filled per correct exercise.
/// - A row for each exercise showing its title, the query used, and a
///   correct / incorrect indicator.
///
/// The navigation back button is hidden. Tapping anywhere on the view pops
/// back to the exercises list, reinforcing the "you're done" moment.
struct BlockResultsView: View {

    // MARK: - Properties

    let block: ExerciseBlock
    let attempts: [ExerciseAttemptRecord]
    let accentColor: Color
    /// Called when the user taps anywhere to go back; pops the full navigation stack.
    let onDismiss: () -> Void

    // MARK: - Computed

    private var correctCount: Int {
        attempts.filter(\.wasCorrect).count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    starsSection
                    attemptsList
                    dismissHint
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
    }

    // MARK: - Stars Section

    private var starsSection: some View {
        VStack(spacing: 12) {
            StarsView(filledCount: correctCount, totalCount: 5, size: 40)
                .padding(.top, 8)

            Text("\(correctCount)/\(attempts.count) correct")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(scoreMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding(.top, 8)
    }

    private var scoreMessage: String {
        switch correctCount {
        case 5:     return "Perfect score!"
        case 4:     return "Great work!"
        case 3:     return "Good effort — keep practicing."
        default:    return "Keep at it — you'll get there."
        }
    }

    // MARK: - Attempts List

    private var attemptsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(attempts.enumerated()), id: \.element.id) { index, record in
                attemptRow(record: record, index: index)

                if index < attempts.count - 1 {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func attemptRow(record: ExerciseAttemptRecord, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Correct / incorrect icon
            Image(systemName: record.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(record.wasCorrect ? .green : .red)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.exerciseTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(record.queryUsed)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Dismiss Hint

    private var dismissHint: some View {
        Text("Tap anywhere to go back")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.bottom, 8)
    }
}
