//
//  VoidComponents.swift
//  Nippardation
//
//  Reusable Void building blocks. The buttons, progress bar and bar chart are Apple's own
//  controls (bordered and prominent buttons, `ProgressView`, Swift Charts) in Void colours with
//  system fonts; the tiles, brand marks, panels and the giant Start stay custom. Everything
//  else is the system's: sheets, navigation bars, lists, pickers and toggles are used directly.
//  Rules: one plasma action per screen; the tile carries state and the glyph never changes;
//  custom pieces keep squared radii and no gradients.
//

import SwiftUI
import UIKit
import Charts

// MARK: - Button styles

/// The giant Start's press feedback: scale .97 over 120ms ease-out. Nothing bounces.
struct VoidScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Panels

struct VoidPanelModifier: ViewModifier {
    var radius: CGFloat
    var line: Color
    var fill: Color

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(line, lineWidth: 1)
            )
    }
}

extension View {
    /// Flat panel with a 1pt inset hairline. Cards/stat tiles use radius 14 + `hairline`;
    /// tiles/pills use radius 12 + `hairline2`.
    func voidPanel(radius: CGFloat = VoidRadius.panel, line: Color = VoidColor.hairline, fill: Color = VoidColor.panel) -> some View {
        modifier(VoidPanelModifier(radius: radius, line: line, fill: fill))
    }

    /// Hull page background behind any screen, with system list backgrounds hidden and the
    /// plasma tint. The navigation bar keeps its system background, so content scrolls under
    /// the standard material (iOS 18) or the Liquid Glass scroll-edge effect (iOS 26).
    func voidScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(VoidColor.hull.ignoresSafeArea())
            .tint(VoidColor.plasmaInk)
    }

}

// MARK: - Tiles

enum WorkoutTileState: Equatable {
    /// Panel + hairline, glyph text-soft (full-strength text on hero and raised tiles).
    case later
    /// Plasma fill, glyph on-plasma.
    case next
    /// Panel + hairline, glyph text-3, plasma check badge.
    case done
    /// The day went by undone. Panel + hairline, glyph text-3, muted skip badge —
    /// deliberately never the plasma check, so skipped never reads as done.
    case skipped
}

/// Square tile holding a workout glyph. The fill/badge tells you if the workout is done,
/// up next, or later. `hero` is the 76pt Today tile.
struct WorkoutTile: View {
    var glyph: VoidIcon?
    var state: WorkoutTileState = .later
    var hero: Bool = false
    /// Sheet variant: panel-2 fill, no hairline (the received-plan day strip).
    var raised: Bool = false
    /// Empty outlined square for rest days in a strip.
    var ghost: Bool = false

    private var size: CGFloat { hero ? VoidSize.tileHero : VoidSize.tile }
    private var radius: CGFloat { hero ? VoidRadius.tileHero : VoidRadius.tile }
    private var glyphSize: CGFloat { hero ? 44 : 30 }

    private var fill: Color {
        if ghost { return .clear }
        if state == .next { return VoidColor.plasma }
        return raised ? VoidColor.panel2 : VoidColor.panel
    }

    private var lineColor: Color {
        if ghost { return VoidColor.hairline }
        if state == .next || raised { return .clear }
        return VoidColor.hairline2
    }

    private var glyphColor: Color {
        switch state {
        case .next: return VoidColor.onPlasma
        case .done, .skipped: return VoidColor.text3
        case .later: return (hero || raised) ? VoidColor.text : VoidColor.textSoft
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(lineColor, lineWidth: 1)
            if let glyph {
                Image(systemName: glyph.systemName)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.medium)
                    .frame(width: glyphSize, height: glyphSize)
                    .foregroundStyle(glyphColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            switch state {
            case .done: DoneBadge().offset(x: 4, y: 4)
            case .skipped: SkippedBadge().offset(x: 4, y: 4)
            case .next, .later: EmptyView()
            }
        }
        .accessibilityHidden(true)
    }
}

/// The `DoneBadge` twin for a skipped day: same square, muted fill, a skip-ahead glyph
/// instead of the check. Reads as "the plan moved past this", not as an achievement.
struct SkippedBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: VoidRadius.badge + 3, style: .continuous)
                .fill(VoidColor.hull)
                .frame(width: VoidSize.badge + 6, height: VoidSize.badge + 6)
            RoundedRectangle(cornerRadius: VoidRadius.badge, style: .continuous)
                .fill(VoidColor.text2)
                .frame(width: VoidSize.badge, height: VoidSize.badge)
            Image(systemName: VoidIcon.skip.systemName)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(VoidColor.hull)
        }
    }
}

/// 20×20 plasma square (radius 5) with a 3pt hull ring and an 11pt check.
struct DoneBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: VoidRadius.badge + 3, style: .continuous)
                .fill(VoidColor.hull)
                .frame(width: VoidSize.badge + 6, height: VoidSize.badge + 6)
            RoundedRectangle(cornerRadius: VoidRadius.badge, style: .continuous)
                .fill(VoidColor.plasma)
                .frame(width: VoidSize.badge, height: VoidSize.badge)
            Image(systemName: VoidIcon.check.systemName)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(VoidColor.onPlasma)
        }
    }
}

/// 3×36 plasma bar flush to the left edge, marking the up-next row.
struct UpNextMark: View {
    var body: some View {
        Rectangle()
            .fill(VoidColor.plasma)
            .frame(width: VoidSize.upNextMark.width, height: VoidSize.upNextMark.height)
            .accessibilityHidden(true)
    }
}

/// 8pt plasma square used as an unread marker.
struct PlasmaDot: View {
    var size: CGFloat = 8
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(VoidColor.plasma)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The ▮ block that prefixes UP NEXT labels. Deliberate; the only unicode-as-icon in the system.
enum VoidGlyphs {
    static let block = "▮"
    static func upNext(_ text: String) -> String { "\(block) \(text)" }
}

// MARK: - Buttons

/// Full-width secondary: the system bordered button at the large control size, in neutral ink
/// (the text colour; plasma fails contrast as text on a light fill). SF subheadline semibold,
/// set outright so an inherited custom font can't reach it; it follows Dynamic Type, and the
/// title shrinks a touch before it truncates.
struct VoidPillButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(VoidColor.text)
        .disabled(!isEnabled)
    }
}

/// Full-width primary: the system prominent button in plasma at the large control size, with an
/// on-plasma title in SF headline. One per screen. `isLoading` swaps the title for a spinner
/// without changing the button's size, and disables the button until it clears.
struct VoidCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VoidCTALabel(title: title, isLoading: isLoading)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(VoidColor.plasma)
        .disabled(!isEnabled || isLoading)
        // The title is hidden, not removed, while loading; say it outright so VoiceOver always has it.
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? Text("Loading") : Text(""))
    }
}

/// The CTA's title. Enabled, it takes on-plasma ink (the system's white fails contrast on plasma);
/// disabled, including while loading, it keeps the system's own disabled look.
private struct VoidCTALabel: View {
    let title: String
    let isLoading: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        if isEnabled {
            content.foregroundStyle(VoidColor.onPlasma)
        } else {
            content
        }
    }

    private var content: some View {
        Text(title)
            .font(.headline)
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    // Loading disables the button, so the spinner sits on the system's disabled
                    // fill, where secondary ink reads in both appearances (on-plasma would not).
                    ProgressView()
                        .controlSize(.regular)
                        .tint(VoidColor.text2)
                }
            }
            .frame(maxWidth: .infinity)
    }
}

/// The giant Start: 200×200, radius 28, plasma, a rippling ring field, play triangle + "Start".
/// Press: scale .97 over 120ms — the rings ride that scale, so they collapse in with the square —
/// plus one faster, brighter ring thrown out of the press. Plays a light impact (`sensoryFeedback`).
struct VoidStartButton: View {
    var title: String = "Start"
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The ripple clock only runs while the button is on screen and live.
    @State private var isOnScreen = false
    /// Clock origin, so the field eases in instead of snapping to mid-flight.
    @State private var appearDate = Date()
    /// The last tap, driving the one fast ring.
    @State private var tapDate: Date?
    /// Reduce Motion tap response: 0…1 brightening of the static rings, no travel.
    @State private var flash: Double = 0
    /// Counts presses; each change plays the light impact. (`tapDate` can't be the trigger:
    /// it only moves when Reduce Motion is off.)
    @State private var tapCount = 0

    private var glow: Double { colorScheme == .dark ? 0.25 : 0.22 }

    var body: some View {
        Button {
            tapCount += 1
            respondToTap()
            action()
        } label: {
            ZStack {
                VoidStartRipple(
                    isRunning: isOnScreen && isEnabled,
                    startDate: appearDate,
                    tapDate: tapDate,
                    flash: flash
                )
                RoundedRectangle(cornerRadius: VoidRadius.start, style: .continuous)
                    .fill(VoidColor.plasma)
                    .frame(width: VoidSize.start, height: VoidSize.start)
                    .shadow(color: VoidColor.plasma.opacity(glow), radius: 25, x: 0, y: 18)
                VStack(spacing: 2) {
                    Image(systemName: VoidIcon.play.systemName)
                        .font(.system(size: 30, weight: .bold))
                        .frame(width: 34, height: 34)
                    Text(title)
                        .font(VoidFont.start)
                }
                .foregroundStyle(VoidColor.onPlasma)
            }
            .frame(width: VoidSize.start + 56, height: VoidSize.start + 56)
            .contentShape(RoundedRectangle(cornerRadius: VoidRadius.start, style: .continuous).size(width: VoidSize.start, height: VoidSize.start).offset(x: 28, y: 28))
        }
        .buttonStyle(VoidScaleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear {
            appearDate = Date()
            isOnScreen = true
        }
        .onDisappear { isOnScreen = false }
    }

    /// Reduce Motion gets a plain brighten-and-settle; otherwise the press throws a ring.
    private func respondToTap() {
        guard isEnabled else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.12)) { flash = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.45)) { flash = 0 }
            }
        } else {
            tapDate = Date()
        }
    }
}

/// The Start button's ring field: rounded rectangles concentric with the 28pt radius that slide
/// out from under the square, widen and dissolve — three in flight, staggered a third of a cycle
/// apart. One `TimelineView(.animation)` drives the lot; nothing here churns state per frame and
/// nothing here lays out (the rings overflow their 200pt frame, as the kit's box-shadow does).
/// Off screen, disabled, or with Reduce Motion on it falls back to the original static rings.
private struct VoidStartRipple: View {
    /// False when the button is off screen or disabled — the clock stops and the rings go static.
    var isRunning: Bool
    /// When the clock started.
    var startDate: Date
    /// The last tap, or nil.
    var tapDate: Date?
    /// Reduce Motion tap response level, 0…1.
    var flash: Double

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The kit's two static glow spreads, used for the Reduce Motion / off-screen fallback.
    // Light mode sits a touch higher; keep that relationship.
    private var ring1: Double { colorScheme == .dark ? 0.06 : 0.08 }
    private var ring2: Double { colorScheme == .dark ? 0.03 : 0.04 }

    /// Peak brightness of a travelling idle band. Well above the static rings' 6% — the ripple has
    /// to read as motion across the room, and a band is only near its peak for a fraction of a second.
    private var idlePeak: Double { colorScheme == .dark ? 0.20 : 0.24 }
    /// The tap band: brighter and faster than the idle ones, so the press clearly throws a ring.
    private var tapPeak: Double { colorScheme == .dark ? 0.42 : 0.48 }

    /// A steady pulse: one ring every 2.8s, three in flight, each a third of a cycle behind the last.
    private let cycle: Double = 2.8
    private let ringCount = 3
    private let reach: CGFloat = 62
    private let tapCycle: Double = 0.85
    private let tapReach: CGFloat = 92

    var body: some View {
        Group {
            if reduceMotion || !isRunning {
                staticRings
            } else {
                TimelineView(.animation) { context in
                    ripple(at: context.date)
                }
            }
        }
        .frame(width: VoidSize.start, height: VoidSize.start)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Static — Reduce Motion, off screen, disabled

    private var staticRings: some View {
        ZStack {
            glowRing(spread: 28, opacity: ring2)
            glowRing(spread: 14, opacity: ring1)
            // The Reduce Motion tap response: the same rings brighten and settle back.
            ZStack {
                glowRing(spread: 28, opacity: ring2 * 0.6)
                glowRing(spread: 14, opacity: ring1 * 0.6)
            }
            .opacity(flash)
        }
    }

    /// A filled rounded rect standing `spread` points proud of the button on every side.
    private func glowRing(spread: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: VoidRadius.start + spread, style: .continuous)
            .fill(VoidColor.plasma.opacity(opacity))
            .frame(width: VoidSize.start + spread * 2, height: VoidSize.start + spread * 2)
    }

    // MARK: Motion

    private func ripple(at now: Date) -> some View {
        let elapsed: Double = max(0, now.timeIntervalSince(startDate))
        // Ease the field in on appear so no ring pops into view mid-flight.
        let fadeIn: Double = min(1, elapsed / 0.7)
        return ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                band(progress: phase(elapsed: elapsed, index: index),
                     peak: idlePeak * fadeIn,
                     reach: reach,
                     width: 16,
                     spread: 14)
            }
            if let tapDate {
                let tapProgress = now.timeIntervalSince(tapDate) / tapCycle
                if tapProgress >= 0, tapProgress <= 1 {
                    band(progress: tapProgress,
                         peak: tapPeak * fadeIn,
                         reach: tapReach,
                         width: 12,
                         spread: 22)
                }
            }
        }
        .blur(radius: 4)
    }

    /// 0…1 position of ring `index` in the cycle, staggered by a third.
    private func phase(elapsed: Double, index: Int) -> Double {
        let raw = elapsed / cycle + Double(index) / Double(ringCount)
        return raw - raw.rounded(.down)
    }

    /// One expanding band. `progress` walks its outer edge from the button's edge out to `reach`,
    /// decelerating, while the band widens by `spread` and fades to nothing. At progress 0 the
    /// band sits entirely under the opaque square, so it reads as emanating from the edge.
    private func band(progress: Double, peak: Double, reach: CGFloat, width: CGFloat, spread: CGFloat) -> some View {
        let p: Double = min(max(progress, 0), 1)
        // Decelerating travel out from the edge, a widening band, then a soft dissolve.
        let eased: Double = 1 - pow(1 - p, 2.2)
        let rise: Double = 0.12
        let fade: Double = p < rise ? p / rise : pow(1 - (p - rise) / (1 - rise), 1.7)
        let distance: CGFloat = reach * CGFloat(eased)
        let line: CGFloat = width + spread * CGFloat(p)
        let side: CGFloat = VoidSize.start + distance * 2
        return RoundedRectangle(cornerRadius: VoidRadius.start + distance, style: .continuous)
            .strokeBorder(VoidColor.plasma.opacity(peak * fade), lineWidth: line)
            .frame(width: side, height: side)
    }
}

// MARK: - Layout pieces

/// Two `VoidPillButton`s (system bordered) side by side, 16pt inset, 10pt gap.
struct VoidPillPair: View {
    let leading: String
    let trailing: String
    var leadingEnabled: Bool = true
    var trailingEnabled: Bool = true
    let onLeading: () -> Void
    let onTrailing: () -> Void

    var body: some View {
        // Side by side while both titles fit; stacked at large text sizes instead of truncating.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { pills }
            VStack(spacing: 10) { pills }
        }
        .padding(.horizontal, VoidSpace.insetCard)
    }

    @ViewBuilder
    private var pills: some View {
        VoidPillButton(title: leading, isEnabled: leadingEnabled, action: onLeading)
        VoidPillButton(title: trailing, isEnabled: trailingEnabled, action: onTrailing)
    }
}

/// Section eyebrow with an optional trailing caption (SENT TO YOU … 1 NEW).
struct VoidSectionRow: View {
    let title: String
    var trailing: String? = nil
    var trailingColor: Color = VoidColor.text2

    var body: some View {
        HStack {
            Text(title).voidEyebrowSm()
            Spacer()
            if let trailing {
                Text(trailing).voidEyebrowSm(trailingColor)
            }
        }
        .padding(.horizontal, VoidSpace.insetText)
    }
}

/// 36pt avatar square (radius 10) with initials in the eyebrow font.
struct VoidAvatar: View {
    let text: String
    var plasma: Bool = false
    var dimmed: Bool = false

    var body: some View {
        Text(text)
            .font(VoidFont.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(plasma ? VoidColor.onPlasma : (dimmed ? VoidColor.text3 : VoidColor.text))
            .frame(width: VoidSize.avatar, height: VoidSize.avatar)
            .background(plasma ? VoidColor.plasma : VoidColor.panel2)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.avatar, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Linear progress in plasma: the system `ProgressView`, which VoiceOver reads as a percentage.
/// Clamped to 0…1; a non-finite value (e.g. 0 / 0) reads as empty.
struct VoidProgressBar: View {
    let progress: Double
    var body: some View {
        ProgressView(value: progress.isFinite ? min(max(progress, 0), 1) : 0)
            .progressViewStyle(.linear)
            .tint(VoidColor.plasma)
    }
}

/// The workouts-per-week bars, in Swift Charts: one `BarMark` per value, radius 3, no axes;
/// the `currentIndex` bar is plasma and the rest text-3. An empty week keeps a 3pt stub so it
/// still reads as a slot. VoiceOver gets a label and value per bar, plus the chart's audio graph.
struct VoidBarChart: View {
    /// Values in 0…1.
    let values: [Double]
    var currentIndex: Int?
    var maxHeight: CGFloat = 56

    var body: some View {
        Chart(values.indices, id: \.self) { index in
            // `.inset(8.5)` is the step minus 8.5pt a side: the spec's fixed 17pt gap at any width.
            // The week label doubles as the category, so the audio graph reads weeks, not indices.
            BarMark(
                x: .value("Week", barLabel(index)),
                y: .value("Share of target", plotted(values[index])),
                width: .inset(8.5)
            )
            .foregroundStyle(index == currentIndex ? VoidColor.plasma : VoidColor.text3)
            .cornerRadius(3)
            .accessibilityLabel(barLabel(index))
            .accessibilityValue(barValue(values[index]))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: 0.0...1.0)
        .frame(height: maxHeight)
    }

    /// A value clamped to 0…1; a non-finite value reads as 0.
    private func clamped(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }

    /// The drawn height: the clamped value, never below the 3pt stub.
    private func plotted(_ value: Double) -> Double {
        max(clamped(value), 3 / Double(max(maxHeight, 3)))
    }

    /// "This week", "Last week", "3 weeks ago": counted back from `currentIndex`.
    private func barLabel(_ index: Int) -> String {
        guard let currentIndex, index <= currentIndex else {
            return "Week \(index + 1) of \(values.count)"
        }
        switch currentIndex - index {
        case 0: return "This week"
        case 1: return "Last week"
        default: return "\(currentIndex - index) weeks ago"
        }
    }

    /// "75 percent of target": the real value, not the stub.
    private func barValue(_ value: Double) -> String {
        "\(Int((clamped(value) * 100).rounded())) percent of target"
    }
}

/// Stat tile: 124pt, padding 14, radius 14, glyph top-left, number + eyebrow-sm bottom-aligned.
struct VoidStatTile: View {
    let icon: VoidIcon
    let value: String
    var unit: String? = nil
    let label: String
    var tone: Color = VoidColor.text
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon.systemName)
                .resizable()
                .scaledToFit()
                .fontWeight(.medium)
                .frame(width: 24, height: 24)
                .foregroundStyle(VoidColor.text)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: progress == nil ? 4 : 6) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(value).voidNumber(tone)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let unit {
                        Text(unit)
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                    }
                }
                if let progress {
                    // The tile's own label already reads the value ("12 / 40").
                    VoidProgressBar(progress: progress)
                        .accessibilityHidden(true)
                }
                Text(label).voidEyebrowSm()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: VoidSize.statTile, alignment: .topLeading)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(unit ?? "")")
    }
}

// MARK: - Text inputs

/// Squared well around a native `TextField`: panel-2 fill, radius 12, Chakra Petch body.
/// At least 44pt tall, and it grows with the text under larger Dynamic Type sizes.
struct VoidTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: VoidIcon? = nil
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon.systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(VoidColor.text2)
            }
            TextField(placeholder, text: $text)
                .font(VoidFont.body)
                .foregroundStyle(VoidColor.text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboard == .URL || keyboard == .emailAddress)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, VoidSpace.s2)
        .frame(minHeight: VoidSize.pill)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

// MARK: - Empty / placeholder

/// Centered placeholder for coming-soon or empty panels.
struct VoidPlaceholder: View {
    let eyebrow: String
    var caption: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(eyebrow).voidEyebrowSm(VoidColor.text3)
            if let caption {
                Text(caption)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VoidSpace.s6)
    }
}

// MARK: - Previews

#Preview("Tiles + buttons") {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                WorkoutTile(glyph: .workoutLegs, state: .done)
                WorkoutTile(glyph: .workoutLower, state: .skipped)
                WorkoutTile(glyph: .workoutPush, state: .next)
                WorkoutTile(glyph: .workoutPull, state: .later)
                WorkoutTile(glyph: .workoutPush, hero: true)
            }
            VoidStartButton { }
            VoidPillPair(leading: "Preview Exercises", trailing: "Swap Workout", onLeading: {}, onTrailing: {})
            VoidCTAButton(title: "Use this plan") { }.padding(.horizontal, 20)
            HStack(spacing: 10) {
                VoidStatTile(icon: .barbell, value: "38.4", unit: "K", label: "Volume · ↑ 6%")
                VoidStatTile(icon: .calendarCheck, value: "12", unit: " / 40", label: "The OG · WK 03 / 08", progress: 0.3)
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview("System-backed controls") {
    ScrollView {
        VStack(spacing: 16) {
            VoidCTAButton(title: "Use this plan") { }
            VoidCTAButton(title: "Activate", isLoading: true) { }
            VoidCTAButton(title: "Continue", isEnabled: false) { }
            VoidPillButton(title: "Save for later") { }
            VoidPillButton(title: "Saved", isEnabled: false) { }
            VoidProgressBar(progress: 0.4)
            VoidBarChart(values: [0.5, 0.75, 0, 1, 0.25, 0.6, 0.9, 0.4], currentIndex: 7)
                .padding(14)
                .voidPanel()
            VoidTextField(placeholder: "Plan name", text: .constant(""), icon: .edit)
        }
        .padding(.horizontal, 16)
    }
    .voidScreen()
}
