//
//  AudioWaveformView.swift
//  Verbio
//
//  Animated waveform visualization for audio recording
//

import SwiftUI

// MARK: - Audio Waveform View

struct AudioWaveformView: View {

    // MARK: - Properties

    let level: Float
    let isRecording: Bool
    let barCount: Int
    let primaryColor: Color
    let secondaryColor: Color

    @State private var animationPhases: [Double]

    // MARK: - Initialization

    init(
        level: Float,
        isRecording: Bool,
        barCount: Int = 5,
        primaryColor: Color = .white,
        secondaryColor: Color = .white.opacity(0.5)
    ) {
        self.level = level
        self.isRecording = isRecording
        self.barCount = barCount
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self._animationPhases = State(initialValue: (0..<barCount).map { _ in Double.random(in: 0...1) })
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    level: isRecording ? level : 0,
                    phase: animationPhases[index],
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                )
            }
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                startAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startAnimation()
            }
        }
    }

    // MARK: - Private Methods

    private func startAnimation() {
        // Randomize phases for organic feel
        withAnimation(.easeInOut(duration: 0.3)) {
            animationPhases = (0..<barCount).map { _ in Double.random(in: 0...1) }
        }
    }
}

// MARK: - Waveform Bar

private struct WaveformBar: View {
    let level: Float
    let phase: Double
    let primaryColor: Color
    let secondaryColor: Color

    @State private var animationAmount: CGFloat = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: calculateHeight())
            .animation(
                .easeInOut(duration: 0.1 + phase * 0.1)
                .repeatForever(autoreverses: true),
                value: level
            )
    }

    private func calculateHeight() -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 40

        if level <= 0 {
            return baseHeight
        }

        // Add variation based on phase for more organic look
        let phaseVariation = CGFloat(1 + sin(phase * .pi * 2) * 0.3)
        let normalizedLevel = CGFloat(level) * phaseVariation

        return baseHeight + (maxHeight - baseHeight) * normalizedLevel
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Idle state
            AudioWaveformView(level: 0, isRecording: false)

            // Low level
            AudioWaveformView(level: 0.2, isRecording: true)

            // Medium level
            AudioWaveformView(level: 0.5, isRecording: true)

            // High level
            AudioWaveformView(level: 0.8, isRecording: true)

            // Custom colors
            AudioWaveformView(
                level: 0.6,
                isRecording: true,
                barCount: 7,
                primaryColor: .cyan,
                secondaryColor: .purple
            )
        }
        .padding()
    }
}
