//
//  Animations.swift
//  Verbio
//
//  Micro-interaction animation curves and durations
//

import SwiftUI

// MARK: - Verbio Animations

enum VerbioAnimations {

    // MARK: - Durations

    enum Duration {
        /// 100ms - Instant feedback
        static let instant: Double = 0.1

        /// 150ms - Quick interactions
        static let quick: Double = 0.15

        /// 200ms - Standard transitions
        static let standard: Double = 0.2

        /// 300ms - Emphasized transitions
        static let emphasized: Double = 0.3

        /// 400ms - Complex transitions
        static let complex: Double = 0.4

        /// 500ms - Slow, dramatic
        static let dramatic: Double = 0.5
    }

    // MARK: - Spring Configurations

    enum Spring {
        /// Snappy spring for quick interactions
        static let snappy = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.7,
            blendDuration: 0
        )

        /// Bouncy spring for playful interactions
        static let bouncy = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.6,
            blendDuration: 0
        )

        /// Smooth spring for subtle transitions
        static let smooth = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0
        )

        /// Gentle spring for large elements
        static let gentle = SwiftUI.Animation.spring(
            response: 0.6,
            dampingFraction: 0.85,
            blendDuration: 0
        )

        /// Interactive spring for drag/gesture response
        static let interactive = SwiftUI.Animation.interactiveSpring(
            response: 0.3,
            dampingFraction: 0.7,
            blendDuration: 0
        )
    }

    // MARK: - Easing Curves

    enum Easing {
        /// Standard ease in out
        static let standard = SwiftUI.Animation.easeInOut(duration: Duration.standard)

        /// Quick ease out for appearing elements
        static let appearQuick = SwiftUI.Animation.easeOut(duration: Duration.quick)

        /// Standard ease out for appearing elements
        static let appear = SwiftUI.Animation.easeOut(duration: Duration.standard)

        /// Ease in for disappearing elements
        static let disappear = SwiftUI.Animation.easeIn(duration: Duration.quick)

        /// Linear for continuous animations
        static let linear = SwiftUI.Animation.linear(duration: Duration.standard)
    }

    // MARK: - Preset Animations

    /// Button press animation
    static let buttonPress = Spring.snappy

    /// Card expand/collapse
    static let cardExpand = Spring.smooth

    /// Modal presentation
    static let modalPresent = Spring.gentle

    /// List item appearance
    static let listItem = Easing.appear

    /// Toggle switch
    static let toggle = Spring.snappy

    /// Slide transition
    static let slide = Spring.smooth

    /// Fade transition
    static let fade = Easing.standard

    /// Scale transition
    static let scale = Spring.bouncy

    /// Recording pulse animation
    static let recordingPulse = SwiftUI.Animation
        .easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)

    /// Loading spinner
    static let loadingSpinner = SwiftUI.Animation
        .linear(duration: 1.0)
        .repeatForever(autoreverses: false)

    /// Waveform animation
    static let waveform = SwiftUI.Animation
        .easeInOut(duration: 0.5)
        .repeatForever(autoreverses: true)
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply snappy spring animation
    func verbioAnimateSnappy() -> some View {
        animation(VerbioAnimations.Spring.snappy, value: UUID())
    }

    /// Animate with button press spring
    func verbioButtonAnimation(_ value: some Equatable) -> some View {
        animation(VerbioAnimations.buttonPress, value: value)
    }

    /// Animate card transitions
    func verbioCardAnimation(_ value: some Equatable) -> some View {
        animation(VerbioAnimations.cardExpand, value: value)
    }

    /// Animate list items
    func verbioListAnimation(_ value: some Equatable) -> some View {
        animation(VerbioAnimations.listItem, value: value)
    }
}

// MARK: - Transition Presets

extension AnyTransition {
    /// Slide up with fade
    static var verbioSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Slide from trailing edge
    static var verbioSlideTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// Scale with fade
    static var verbioScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
    }

    /// Pop in animation
    static var verbioPop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }

    /// Blur transition
    static var verbioBlur: AnyTransition {
        .opacity.combined(with: .scale(scale: 1.02))
    }
}

// MARK: - Staggered Animation Helper

struct StaggeredAnimation: ViewModifier {
    let index: Int
    let baseDelay: Double

    func body(content: Content) -> some View {
        content
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(
                    VerbioAnimations.Spring.smooth.delay(Double(index) * baseDelay)
                ) {
                    // Animation applied via state change in parent
                }
            }
    }
}

extension View {
    /// Apply staggered animation based on index
    func verbioStaggered(index: Int, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredAnimation(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Preview

#Preview("Animations Demo") {
    AnimationsPreview()
}

private struct AnimationsPreview: View {
    @State private var isPressed = false
    @State private var isExpanded = false
    @State private var showCard = true

    var body: some View {
        ScrollView {
            VStack(spacing: VerbioSpacing.xxl) {
                Text("Animation Demos")
                    .font(.title.bold())

                // Button Press Demo
                VStack(spacing: VerbioSpacing.sm) {
                    Text("Button Press (Snappy Spring)")
                        .font(.headline)

                    Circle()
                        .fill(Color.orange)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(VerbioAnimations.buttonPress, value: isPressed)
                        .onTapGesture {
                            isPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isPressed = false
                            }
                        }

                    Text("Tap the circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Card Expand Demo
                VStack(spacing: VerbioSpacing.sm) {
                    Text("Card Expand (Smooth Spring)")
                        .font(.headline)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.2))
                        .frame(height: isExpanded ? 200 : 100)
                        .animation(VerbioAnimations.cardExpand, value: isExpanded)
                        .onTapGesture {
                            isExpanded.toggle()
                        }

                    Text("Tap to expand/collapse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Transition Demo
                VStack(spacing: VerbioSpacing.sm) {
                    Text("Transitions")
                        .font(.headline)

                    Button(showCard ? "Hide Card" : "Show Card") {
                        withAnimation(VerbioAnimations.Spring.smooth) {
                            showCard.toggle()
                        }
                    }

                    if showCard {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 150, height: 100)
                            .transition(.verbioScale)
                    }
                }
            }
            .padding()
        }
    }
}
