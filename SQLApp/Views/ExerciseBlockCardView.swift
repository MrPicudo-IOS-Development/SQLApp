//
//  ExerciseBlockCardView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 16/03/26.
//

import SwiftUI

/// A reusable card that represents a block of 5 exercises sharing the same table(s).
///
/// Layout:
/// - Left: a small square image related to the table data, with an optional score
///   arc badge overlaid when the block has been completed at least once.
/// - Right: the block title, a row of SQL keyword capsules, and a summary text.
struct ExerciseBlockCardView: View {

    /// The exercise block data to display.
    let block: ExerciseBlock

    /// The accent color used for SQL keyword capsules.
    let accentColor: Color

    /// The best score (0–100) ever achieved for this block, or `nil` if never completed.
    var bestScore: Int? = nil

    // MARK: - Score arc color

    private var scoreColor: Color {
        guard let score = bestScore else { return accentColor }
        switch score {
        case 100:   return .green
        case 70...: return accentColor
        case 40...: return .orange
        default:    return .red
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Square image on the left, with score arc badge when completed
            Image(systemName: block.imageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(accentColor)
                .frame(width: 56, height: 56)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    if let score = bestScore {
                        ScoreArcBadge(score: score, color: scoreColor)
                            .offset(x: 8, y: 8)
                    }
                }

            // Text content on the right
            VStack(alignment: .leading, spacing: 6) {
                Text(block.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // SQL keywords as small capsules
                FlowLayout(spacing: 4) {
                    ForEach(block.sqlKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(block.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Score Arc Badge

/// A compact circular arc badge showing a percentage score.
/// Designed to sit unobtrusively in the corner of an icon.
private struct ScoreArcBadge: View {

    let score: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(width: 26, height: 26)

            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: 20, height: 20)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 20, height: 20)

            Text("\(score)")
                .font(.system(size: 6, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Flow Layout

/// A simple horizontal flow layout that wraps items to the next line when they
/// exceed the available width. Used for SQL keyword capsules.
struct FlowLayout: Layout {

    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return ArrangementResult(
            positions: positions,
            size: CGSize(width: maxWidth, height: totalHeight)
        )
    }

    private struct ArrangementResult {
        var positions: [CGPoint]
        var size: CGSize
    }
}
