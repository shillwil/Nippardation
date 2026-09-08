//
//  VoidComponents.swift
//  Nippardation
//
//  Reusable Void building blocks: tiles, pills, the giant Start, controls,
//  panels, rows, sheets, press styles and haptics.
//  Rules: one plasma action per screen; warning red is a label colour, never a fill;
//  the tile carries state and the glyph never changes; squared radii, no gradients.
//

import SwiftUI
import UIKit

// MARK: - Haptics

enum VoidHaptics {
    /// Light impact — Start, checkpoint reached. Nothing on tab change.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Button styles

/// Secondary press feedback: the panel fills panel-2 while pressed. Draws the panel itself.
struct VoidPanelButtonStyle: ButtonStyle {
    var radius: CGFloat = VoidRadius.tile
    var line: Color = VoidColor.hairline2
    var fill: Color = VoidColor.panel
    var pressedFill: Color = VoidColor.panel2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedFill : fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(line, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Primary press feedback: scale .97 over 120ms ease-out. Nothing bounces.
struct VoidScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Row press feedback: the row fills panel-2 while pressed, no shape of its own.
struct VoidRowButtonStyle: ButtonStyle {
    var pressedFill: Color = VoidColor.panel2
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedFill : Color.clear)
            .contentShape(Rectangle())
    }
}

/// A button with no visual feedback of its own (menus, icon buttons that draw their own state).
struct VoidPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
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

    /// Hull page background behind any screen, with system list backgrounds hidden.
    func voidScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(VoidColor.hull.ignoresSafeArea())
            .toolbarBackground(VoidColor.hull, for: .navigationBar)
            .tint(VoidColor.plasma)
    }

    /// Hides the system navigation bar on a tab root that draws its own eyebrow row.
    func voidRootScreen() -> some View {
        self
            .voidScreen()
            .toolbar(.hidden, for: .navigationBar)
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
        case .done: return VoidColor.text3
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
            if state == .done {
                DoneBadge().offset(x: 4, y: 4)
            }
        }
        .accessibilityHidden(true)
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

/// Secondary pill: 44pt, radius 12, panel + hairline-2, SF 15 semibold. Press: panel-2 fill.
struct VoidPillButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VoidFont.button)
                .foregroundStyle(VoidColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: VoidSize.pill)
        }
        .buttonStyle(VoidPanelButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Full-width primary: 50pt, radius 12, plasma fill, SF 17 semibold on-plasma. One per screen.
struct VoidCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(VoidFont.buttonLg)
                    .foregroundStyle(VoidColor.onPlasma)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(VoidColor.onPlasma)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: VoidSize.cta)
            .background(VoidColor.plasma)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
        }
        .buttonStyle(VoidScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Destructive full-width button: panel fill, warning label. Warning is never a fill.
struct VoidDestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VoidFont.button)
                .foregroundStyle(VoidColor.warning)
                .frame(maxWidth: .infinity)
                .frame(height: VoidSize.pill)
        }
        .buttonStyle(VoidPanelButtonStyle())
    }
}

/// The giant Start: 200×200, radius 28, plasma, a rippling ring field, play triangle + "Start".
/// Press: scale .97 over 120ms — the rings ride that scale, so they collapse in with the square —
/// plus one faster, brighter ring thrown out of the press. Fires a light haptic.
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

    private var glow: Double { colorScheme == .dark ? 0.25 : 0.22 }

    var body: some View {
        Button {
            VoidHaptics.light()
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

    // The kit's two static glow spreads. Light mode sits a touch higher; keep that relationship.
    private var ring1: Double { colorScheme == .dark ? 0.06 : 0.08 }
    private var ring2: Double { colorScheme == .dark ? 0.03 : 0.04 }
    /// Ceiling for a travelling ring: what the two static rings composite to where they overlap.
    private var tapPeak: Double { colorScheme == .dark ? 0.09 : 0.115 }

    /// A slow pulse: one ring every 3.4s, three in flight, each a third of a cycle behind the last.
    private let cycle: Double = 3.4
    private let ringCount = 3
    private let reach: CGFloat = 44
    private let tapCycle: Double = 0.9
    private let tapReach: CGFloat = 64

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
                     peak: ring1 * fadeIn,
                     reach: reach,
                     width: 14,
                     spread: 10)
            }
            if let tapDate {
                let tapProgress = now.timeIntervalSince(tapDate) / tapCycle
                if tapProgress >= 0, tapProgress <= 1 {
                    band(progress: tapProgress,
                         peak: tapPeak * fadeIn,
                         reach: tapReach,
                         width: 10,
                         spread: 18)
                }
            }
        }
        .blur(radius: 5)
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

/// Small 32pt control (radius 8, panel + hairline-2) holding one glyph — the ··· and link buttons.
struct VoidControlButton: View {
    let icon: VoidIcon
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(VoidColor.text)
                .frame(width: VoidSize.control, height: VoidSize.control)
        }
        .buttonStyle(VoidPanelButtonStyle(radius: VoidRadius.control))
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Same chrome as `VoidControlButton`, but the label is a `Menu` trigger.
struct VoidControlMenu<Content: View>: View {
    let icon: VoidIcon
    var accessibilityLabel: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            Image(systemName: icon.systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(VoidColor.text)
                .frame(width: VoidSize.control, height: VoidSize.control)
                .background(VoidColor.panel)
                .clipShape(RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                        .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                )
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// 28pt chip: panel + hairline-2, radius 8, glyph 14pt + eyebrow label tracked .06em (the streak chip).
struct VoidChip: View {
    var icon: VoidIcon?
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon.systemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoidColor.text)
            }
            Text(text).voidChipLabel()
        }
        .padding(.leading, icon == nil ? 10 : 8)
        .padding(.trailing, 10)
        .frame(height: VoidSize.chip)
        .voidPanel(radius: VoidRadius.control, line: VoidColor.hairline2)
    }
}

/// 28pt segmented control: panel + hairline-2, 2pt padding, selected item panel-2 with 6pt radius.
struct VoidSegmentedControl<Item: Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    @Binding var selection: Item

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                let on = item == selection
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .voidChipLabel(on ? VoidColor.text : VoidColor.text2)
                        .padding(.horizontal, 12)
                        .frame(height: VoidSize.chip - 4)
                        .background(on ? VoidColor.panel2 : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.mark, style: .continuous))
                }
                .buttonStyle(VoidPlainButtonStyle())
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .padding(2)
        .voidPanel(radius: VoidRadius.control, line: VoidColor.hairline2)
    }
}

// MARK: - Layout pieces

/// The eyebrow row at the top of a tab screen: leading label, trailing accessory.
struct VoidEyebrowRow<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title).voidEyebrow()
                .lineLimit(1)
            Spacer(minLength: VoidSpace.s3)
            trailing()
        }
        .padding(.horizontal, VoidSpace.insetText)
        .padding(.top, VoidSpace.topContent)
    }
}

extension VoidEyebrowRow where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title, trailing: { EmptyView() })
    }
}

/// Two pills side by side, 16pt inset, 10pt gap, sitting above the tab bar.
struct VoidPillPair: View {
    let leading: String
    let trailing: String
    var leadingEnabled: Bool = true
    var trailingEnabled: Bool = true
    let onLeading: () -> Void
    let onTrailing: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VoidPillButton(title: leading, isEnabled: leadingEnabled, action: onLeading)
            VoidPillButton(title: trailing, isEnabled: trailingEnabled, action: onTrailing)
        }
        .padding(.horizontal, VoidSpace.insetCard)
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

/// A list panel: radius 14, panel + hairline, rows separated by hairlines, inner inset 14.
struct VoidListPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 14)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
        .padding(.horizontal, VoidSpace.insetCard)
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

/// 16pt chevron, stroke-weight matched to the glyph set.
struct VoidChevron: View {
    var color: Color = VoidColor.text3
    var body: some View {
        Image(systemName: VoidIcon.chevron.systemName)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
    }
}

/// Hairline separator between rows.
struct VoidHairline: View {
    var body: some View {
        Rectangle().fill(VoidColor.hairline).frame(height: 1)
    }
}

/// 4pt progress bar, plasma on track, no radius.
struct VoidProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(VoidColor.track)
                Rectangle().fill(VoidColor.plasma)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

/// Sheet grabber: 36×5, text-3.
struct VoidGrabber: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(VoidColor.text3)
            .frame(width: VoidSize.grabber.width, height: VoidSize.grabber.height)
            .accessibilityHidden(true)
    }
}

/// Simple bar chart: bars 56pt max, 17pt gaps, radius 3; past bars text-3, `currentIndex` plasma.
struct VoidBarChart: View {
    /// Values in 0…1.
    let values: [Double]
    var currentIndex: Int?
    var maxHeight: CGFloat = 56

    var body: some View {
        HStack(alignment: .bottom, spacing: 17) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(index == currentIndex ? VoidColor.plasma : VoidColor.text3)
                    .frame(height: max(3, maxHeight * min(max(value, 0), 1)))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: maxHeight, alignment: .bottom)
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
                    VoidProgressBar(progress: progress)
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

// MARK: - Sheet chrome

/// Bottom-sheet body chrome: panel fill, top radius 16, 1pt top hairline, grabber, padding 10/20/34.
/// Use inside `.sheet` with `.presentationBackground(VoidColor.panel)` and detents.
struct VoidSheetContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            VoidGrabber()
                .padding(.top, 10)
                .padding(.bottom, 22)
            content()
        }
        .padding(.horizontal, VoidSpace.insetText)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background(VoidColor.panel)
        .overlay(alignment: .top) {
            Rectangle().fill(VoidColor.hairline2).frame(height: 1)
        }
    }
}

extension View {
    /// Applies the Void sheet presentation chrome (panel background, hidden system drag indicator, corner radius).
    func voidSheet() -> some View {
        self
            .presentationDragIndicator(.hidden)
            .presentationBackground(VoidColor.panel)
            .presentationCornerRadius(VoidRadius.tabBar)
    }
}

// MARK: - Text inputs

/// Squared text field well: panel-2 fill, radius 12, SF 15.
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
        .frame(height: VoidSize.pill)
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
                WorkoutTile(glyph: .workoutPush, state: .next)
                WorkoutTile(glyph: .workoutPull, state: .later)
                WorkoutTile(glyph: .workoutPush, hero: true)
            }
            VoidStartButton { }
            VoidPillPair(leading: "Preview Exercises", trailing: "Swap Workout", onLeading: {}, onTrailing: {})
            VoidCTAButton(title: "Use this plan") { }.padding(.horizontal, 20)
            HStack {
                VoidChip(icon: .flame, text: "03 WK")
                VoidSegmentedControl(items: ["ME", "CREW"], label: { $0 }, selection: .constant("ME"))
                VoidControlButton(icon: .more, accessibilityLabel: "More") { }
            }
            HStack(spacing: 10) {
                VoidStatTile(icon: .barbell, value: "38.4", unit: "K", label: "Volume · ↑ 6%")
                VoidStatTile(icon: .calendarCheck, value: "12", unit: " / 40", label: "The OG · WK 03 / 08", progress: 0.3)
            }
            .padding(.horizontal, 16)
        }
    }
}
