//
//  ExerciseBlockCardView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 16/03/26.
//

import SwiftUI

/// A reusable card that represents a block of 5 exercises sharing the same table(s).
///
/// Layout:
/// - Left: a small square image with 5 small stars below it, vertically centered.
///   Stars are gray and empty by default; yellow and filled proportionally once
///   the block has been completed at least once.
/// - Right: the block title, a row of SQL keyword capsules, and a summary text.
struct ExerciseBlockCardView: View {

    /// The exercise block data to display.
    let block: ExerciseBlock

    /// The accent color used for SQL keyword capsules.
    let accentColor: Color

    /// The best star count (0–5) ever achieved for this block, or `nil` if never completed.
    var bestStars: Int? = nil

    // MARK: - Layout constants

    /// Fixed inner height for all cards.
    private static let cardContentHeight: CGFloat = 135

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Image + stars column, vertically centered
            VStack(spacing: 6) {
                Image(block.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)

                StarsView(
                    filledCount: bestStars ?? 0,
                    totalCount: 5,
                    size: 12,
                    color: bestStars != nil ? .yellow : Color(.systemGray4)
                )
            }

            // Text content on the right — fixed height, top-aligned
            VStack(alignment: .leading, spacing: 6) {
                Text(block.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                // SQL keywords as small capsules, clipped to 3 rows max
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
                .frame(maxHeight: 60, alignment: .topLeading)
                .clipped()

                Text(block.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(height: Self.cardContentHeight, alignment: .top)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stars View

/// A row of star icons: filled stars for correct answers, empty stars for the rest.
///
/// Reused by ``ExerciseBlockCardView`` (small, on cards) and
/// ``BlockResultsView`` (large, on the results screen).
struct StarsView: View {

    /// How many stars should be filled (0…totalCount).
    let filledCount: Int

    /// Total number of stars to display.
    let totalCount: Int

    /// Point size for each star icon.
    var size: CGFloat = 24

    /// The color applied to all stars (filled and empty).
    /// Defaults to yellow.
    var color: Color = .yellow

    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<totalCount, id: \.self) { index in
                Image(systemName: index < filledCount ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(color)
            }
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
