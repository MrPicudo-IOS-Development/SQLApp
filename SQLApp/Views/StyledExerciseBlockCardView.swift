//
//  StyledExerciseBlockCardView.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 20/03/26.
//

import SwiftUI

/// A style-aware exercise block card that renders with structurally distinct
/// layouts depending on the selected ``AppStyle``.
///
/// Each style has its own layout, typography, badge shapes, star presentation,
/// and card structure — not just a color palette swap.
struct StyledExerciseBlockCardView: View {

    let block: ExerciseBlock
    let style: AppStyle
    var bestStars: Int? = nil

    /// Fixed height for all card styles so cards with less content
    /// still match those with the maximum (title + 3 keyword rows + 3 summary lines).
    private static let fixedCardHeight: CGFloat = 220

    var body: some View {
        Group {
            switch style {
            case .vibrant:
                vibrantCard
            case .glassmorphism:
                glassmorphismCard
            case .minimalism:
                minimalismCard
            case .darkMode:
                darkModeCard
            case .bentoGrid:
                bentoGridCard
            }
        }
        .frame(height: Self.fixedCardHeight)
    }

    // MARK: - Vibrant & Block

    /// Bold, geometric, block-based layout.
    /// Image on top (full width), thick accent bar, keywords as rectangular blocks,
    /// stars as small filled/empty squares.
    private var vibrantCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width image banner
            ZStack(alignment: .bottomLeading) {
                Image(block.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()

                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, Color(hex: 0x0F172A).opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 50)

                // Title over image
                Text(block.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            // Thick accent bar
            Rectangle()
                .fill(style.accentColor)
                .frame(height: 4)

            // Content area
            VStack(alignment: .leading, spacing: 8) {
                // Keywords as rectangular blocks
                FlowLayout(spacing: 6) {
                    ForEach(block.sqlKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundStyle(Color(hex: 0x0F172A))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(style.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }

                Text(block.summary)
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x94A3B8))
                    .lineLimit(2)

                // Stars
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        let filled = index < (bestStars ?? 0)
                        Image(systemName: filled ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(filled
                                             ? style.accentColor
                                             : Color(hex: 0x334155))
                    }
                }
            }
            .padding(12)
            .background(Color(hex: 0x0F172A))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Glassmorphism

    /// Frosted glass card with circular image, glass-pill tags, and glowing dot stars.
    /// Vertical centered layout with translucent layering.
    private var glassmorphismCard: some View {
        VStack(spacing: 12) {
            // Circular image with glow ring
            Image(block.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(style.accentColor.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: style.accentColor.opacity(0.3), radius: 8)

            // Title centered
            Text(block.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: 0xF8FAFC))

            // Keywords as frosted glass pills
            FlowLayout(spacing: 6) {
                ForEach(block.sqlKeywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(style.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(style.accentColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)

            Text(block.summary)
                .font(.caption)
                .foregroundStyle(Color(hex: 0xA5B4FC))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Stars with glow
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    let filled = index < (bestStars ?? 0)
                    Image(systemName: filled ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(filled ? style.accentColor : Color.white.opacity(0.2))
                        .shadow(color: filled ? style.accentColor.opacity(0.6) : .clear,
                                radius: 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Minimalism

    /// Ultra-clean horizontal layout. No decorative elements.
    /// Keywords as plain text with underlines. Stars as simple dashes/lines.
    /// Sharp corners, thin border, generous whitespace.
    private var minimalismCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Simple image, no effects
            Image(block.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(block.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: 0x1E293B))

                // Keywords as plain text separated by dots
                HStack(spacing: 0) {
                    ForEach(Array(block.sqlKeywords.enumerated()), id: \.offset) { index, keyword in
                        if index > 0 {
                            Text("  ·  ")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0xCBD5E1))
                        }
                        Text(keyword)
                            .font(.system(.caption2, design: .default))
                            .fontWeight(.medium)
                            .foregroundStyle(style.accentColor)
                            .textCase(.uppercase)
                    }
                }

                Text(block.summary)
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x94A3B8))
                    .lineLimit(2)

                // Stars
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        let filled = index < (bestStars ?? 0)
                        Image(systemName: filled ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(filled
                                             ? style.accentColor
                                             : Color(hex: 0xE2E8F0))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .overlay(
            Rectangle()
                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
        )
    }

    // MARK: - Dark Mode

    /// OLED black card with neon accent glow. Image with glow border,
    /// outlined keyword capsules, stars with neon glow effect.
    private var darkModeCard: some View {
        HStack(alignment: .center, spacing: 12) {
            // Image with neon glow border
            VStack(spacing: 8) {
                Image(block.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style.accentColor.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: style.accentColor.opacity(0.3), radius: 6)

                // Stars with glow
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        let filled = index < (bestStars ?? 0)
                        Image(systemName: filled ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(filled ? style.accentColor : Color(hex: 0x334155))
                            .shadow(color: filled ? style.accentColor.opacity(0.6) : .clear,
                                    radius: 3)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(block.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: 0xF8FAFC))

                // Outlined keyword capsules (border only, no fill)
                FlowLayout(spacing: 4) {
                    ForEach(block.sqlKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(style.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .overlay(
                                Capsule()
                                    .stroke(style.accentColor.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .frame(maxHeight: 50, alignment: .topLeading)
                .clipped()

                Text(block.summary)
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x94A3B8))
                    .lineLimit(2)
            }
            .frame(maxHeight: 130, alignment: .top)
        }
        .padding(12)
        .background(Color(hex: 0x000000))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0x1E293B), lineWidth: 1)
        )
    }

    // MARK: - Bento Grid

    /// Modular grid layout. Image, title, keywords, and stars each in
    /// their own bordered cell. Clean Apple-style with red accent.
    private var bentoGridCard: some View {
        VStack(spacing: 0) {
            // Top row: Image cell | Title + summary cell
            HStack(spacing: 0) {
                // Image cell
                Image(block.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(style.accentColor)
                            .frame(width: 3, height: 90)
                    }

                // Vertical divider
                Rectangle()
                    .fill(Color(hex: 0x1E293B))
                    .frame(width: 1)

                // Title + summary cell
                VStack(alignment: .leading, spacing: 6) {
                    Text(block.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: 0xF8FAFC))

                    Text(block.summary)
                        .font(.caption)
                        .foregroundStyle(Color(hex: 0x94A3B8))
                        .lineLimit(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 90)
            }

            // Horizontal divider
            Rectangle()
                .fill(Color(hex: 0x1E293B))
                .frame(height: 1)

            // Bottom row: Keywords cell | Stars cell
            HStack(spacing: 0) {
                // Keywords cell
                FlowLayout(spacing: 4) {
                    ForEach(block.sqlKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(style.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(style.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Vertical divider
                Rectangle()
                    .fill(Color(hex: 0x1E293B))
                    .frame(width: 1)
                    .frame(height: 36)

                // Stars cell
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        let filled = index < (bestStars ?? 0)
                        Image(systemName: filled ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundStyle(filled
                                             ? style.accentColor
                                             : Color(hex: 0x334155))
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .background(Color(hex: 0x020617))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0x1E293B), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("All Styles") {
    let block = ExerciseBlock(
        imageName: "Videogames",
        sqlKeywords: ["INNER JOIN", "LEFT JOIN", "ON"],
        summary: "Query videogame data using joins to combine tables for deeper analysis.",
        tableNames: ["VideoGames"],
        jsonFileName: "preview",
        exercises: []
    )

    ScrollView {
        VStack(spacing: 20) {
            ForEach(AppStyle.allCases) { style in
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    StyledExerciseBlockCardView(
                        block: block,
                        style: style,
                        bestStars: 4
                    )
                }
            }
        }
        .padding()
    }
}
