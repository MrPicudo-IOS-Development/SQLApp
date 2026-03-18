//
//  BlockResultsView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 18/03/26.
//

import SwiftUI

/// Summary screen shown after the user completes all exercises in a block.
///
/// Displays:
/// - A circular score ring with the percentage of correct answers.
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

    private var score: Int {
        guard !attempts.isEmpty else { return 0 }
        return Int((Double(correctCount) / Double(attempts.count)) * 100)
    }

    private var scoreColor: Color {
        switch score {
        case 100:       return .green
        case 70...:     return accentColor
        case 40...:     return .orange
        default:        return .red
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    scoreRing
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

    // MARK: - Score Ring

    private var scoreRing: some View {
        VStack(spacing: 12) {
            ZStack {
                // Track
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 14)
                    .frame(width: 140, height: 140)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)
                    .animation(.easeOut(duration: 0.8), value: score)

                // Score label
                VStack(spacing: 2) {
                    Text("\(score)%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text("\(correctCount)/\(attempts.count) correct")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(scoreMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding(.top, 8)
    }

    private var scoreMessage: String {
        switch score {
        case 100:   return "Perfect score! 🎉"
        case 80...: return "Great work!"
        case 60...: return "Good effort — keep practicing."
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
                    .lineLimit(2)
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
