//
//  AudioLevelIndicator.swift
//  Verbio
//
//  Circular audio level meter
//

import SwiftUI

// MARK: - Audio Level Indicator

struct AudioLevelIndicator: View {

    // MARK: - Properties

    let level: Float
    let isActive: Bool
    let size: CGFloat
    let lineWidth: CGFloat
    let primaryColor: Color
    let backgroundColor: Color

    // MARK: - Initialization

    init(
        level: Float,
        isActive: Bool,
        size: CGFloat = 80,
        lineWidth: CGFloat = 4,
        primaryColor: Color = .white,
        backgroundColor: Color = .white.opacity(0.2)
    ) {
        self.level = level
        self.isActive = isActive
        self.size = size
        self.lineWidth = lineWidth
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Level indicator
            Circle()
                .trim(from: 0, to: isActive ? CGFloat(level) : 0)
                .stroke(
                    primaryColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.1), value: level)

            // Pulsing ring when active
            if isActive {
                Circle()
                    .stroke(primaryColor.opacity(0.3), lineWidth: lineWidth / 2)
                    .scaleEffect(1 + CGFloat(level) * 0.2)
                    .opacity(Double(1 - level))
                    .animation(.easeOut(duration: 0.2), value: level)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Compact Level Indicator

struct CompactLevelIndicator: View {
    let level: Float
    let isActive: Bool
    let color: Color

    init(
        level: Float,
        isActive: Bool,
        color: Color = .white
    ) {
        self.level = level
        self.isActive = isActive
        self.color = color
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index))
                    .frame(width: 3, height: barHeight(for: index))
            }
        }
        .animation(.easeOut(duration: 0.1), value: level)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 20
        let threshold = Float(index + 1) / 3.0

        guard isActive else { return baseHeight }

        if level >= threshold {
            return maxHeight * CGFloat(min(1, level / threshold))
        }

        return baseHeight
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Float(index + 1) / 3.0
        let isActive = self.isActive && level >= threshold * 0.8

        return isActive ? color : color.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Circular indicators
            HStack(spacing: 30) {
                AudioLevelIndicator(level: 0, isActive: false)
                AudioLevelIndicator(level: 0.3, isActive: true)
                AudioLevelIndicator(level: 0.7, isActive: true)
                AudioLevelIndicator(level: 1.0, isActive: true)
            }

            // Compact indicators
            HStack(spacing: 30) {
                CompactLevelIndicator(level: 0, isActive: false)
                CompactLevelIndicator(level: 0.3, isActive: true)
                CompactLevelIndicator(level: 0.7, isActive: true)
                CompactLevelIndicator(level: 1.0, isActive: true)
            }

            // Custom colors
            HStack(spacing: 30) {
                AudioLevelIndicator(
                    level: 0.6,
                    isActive: true,
                    primaryColor: .green
                )
                AudioLevelIndicator(
                    level: 0.8,
                    isActive: true,
                    primaryColor: .orange
                )
                AudioLevelIndicator(
                    level: 1.0,
                    isActive: true,
                    primaryColor: .red
                )
            }
        }
        .padding()
    }
}
