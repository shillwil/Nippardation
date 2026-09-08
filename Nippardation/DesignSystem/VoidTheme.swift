//
//  VoidTheme.swift
//  Nippardation
//
//  Void design system tokens — mirrors void-ds/tokens/*.css 1:1.
//  Fonts: Michroma-Regular.ttf and ChakraPetch-SemiBold.ttf are bundled under
//  Resources/Fonts and registered via UIAppFonts in Info.plist.
//
//  Glyphs: the app uses SF Symbols (its existing icon set) rather than the
//  SVGs that shipped with the design bundle. See `VoidIcon`.
//

import SwiftUI
import UIKit

// MARK: - Color

enum VoidColor {
    private static func dyn(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    private static func hex(_ h: UInt32, _ a: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((h >> 16) & 0xFF)/255, green: CGFloat((h >> 8) & 0xFF)/255, blue: CGFloat(h & 0xFF)/255, alpha: a)
    }

    /// Page background as a `UIColor`, for UIKit-level chrome (the window background).
    static let hullUIColor = UIColor { $0.userInterfaceStyle == .dark ? hex(0x05070C) : hex(0xE9EEF4) }
    /// Page background.
    static let hull       = Color(hullUIColor)
    /// Cards, tiles, pills.
    static let panel      = dyn(hex(0xFFFFFF), hex(0x0C1119))
    /// Active tab, stepper wells, pressed panel.
    static let panel2     = dyn(hex(0xDCE4EE), hex(0x161E2A))
    static let text       = dyn(hex(0x0B1220), hex(0xDCE6F2))
    static let text2      = dyn(hex(0x0B1220, 0.62), hex(0xBECDE0, 0.62))
    static let text3      = dyn(hex(0x0B1220, 0.35), hex(0xBECDE0, 0.35))
    static let textSoft   = dyn(hex(0x0B1220, 0.70), hex(0xDCE6F2, 0.70))
    /// Row separators.
    static let hairline   = dyn(hex(0x0B1220, 0.10), hex(0xBECDE0, 0.08))
    /// Tile + pill borders.
    static let hairline2  = dyn(hex(0x0B1220, 0.10), hex(0xBECDE0, 0.10))
    /// THE action color. Deepens in light mode so marks hold on white.
    static let plasma     = dyn(hex(0x00A3C4), hex(0x33E0FF))
    static let onPlasma   = Color(hex(0x05070C))
    /// Instrument red: labels + PR count only. Never a fill.
    static let warning    = dyn(hex(0xB8323A), hex(0xE0525A))
    static let tabBar     = dyn(hex(0xFFFFFF, 0.94), hex(0x0C1119, 0.97))
    static let tabBarLine = dyn(hex(0x0B1220, 0.10), hex(0xBECDE0, 0.12))
    /// Progress-bar track (rgba(190,205,224,.12) in the kit).
    static let track      = dyn(hex(0x0B1220, 0.12), hex(0xBECDE0, 0.12))
    /// Scrim behind bottom sheets.
    static let scrim      = Color(hex(0x05070C, 0.72))
}

// MARK: - Type

enum VoidFont {
    // Display — Michroma, one weight. Always uppercase, tracking 0.02em.
    static let wordHero   = Font.custom("Michroma-Regular", size: 44)
    static let wordRow    = Font.custom("Michroma-Regular", size: 30)
    static let numberHero = Font.custom("Michroma-Regular", size: 48)
    static let number     = Font.custom("Michroma-Regular", size: 24)
    // Labels — Chakra Petch SemiBold. Always uppercase, tracking 0.12em (readout 0.06em).
    static let eyebrow    = Font.custom("ChakraPetch-SemiBold", size: 12)
    static let eyebrowSm  = Font.custom("ChakraPetch-SemiBold", size: 11)
    static let readout    = Font.custom("ChakraPetch-SemiBold", size: 13)
    // UI — SF
    static let body       = Font.system(size: 15)
    static let bodyStrong = Font.system(size: 15, weight: .semibold)
    static let caption    = Font.system(size: 13)
    static let caption2   = Font.system(size: 12)
    static let button     = Font.system(size: 15, weight: .semibold)
    static let buttonLg   = Font.system(size: 17, weight: .semibold)
    static let start      = Font.system(size: 20, weight: .bold)
    static let tab        = Font.system(size: 10, weight: .medium)
    static let stepper    = Font.system(size: 20, weight: .bold).monospacedDigit()
    /// Section / sheet titles in SF.
    static let title      = Font.system(size: 20, weight: .bold)

    /// Font names as registered in the bundle (UIAppFonts).
    static let displayFontName = "Michroma-Regular"
    static let labelFontName   = "ChakraPetch-SemiBold"

    // Tracking, in points (em × size).
    enum Tracking {
        static let eyebrow: CGFloat   = 12 * 0.12
        static let eyebrowSm: CGFloat = 11 * 0.12
        static let readout: CGFloat   = 13 * 0.06
        static func display(size: CGFloat) -> CGFloat { size * 0.02 }
    }
}

// MARK: - Spacing

enum VoidSpace {
    static let s1: CGFloat = 4, s2: CGFloat = 8, s3: CGFloat = 12, s4: CGFloat = 16, s5: CGFloat = 20, s6: CGFloat = 24
    /// Cards, pills, tab bar sit 16 from the edge.
    static let insetCard: CGFloat = 16
    /// Text and rows sit 20 from the edge.
    static let insetText: CGFloat = 20
    /// First content line sits 112pt down on a 393×852 canvas whose status bar is 54pt,
    /// i.e. 58pt below the top safe-area inset.
    static let topContent: CGFloat = 58
    /// Space between the bottom pills and the tab bar.
    static let pillsBottom: CGFloat = 24
}

// MARK: - Sizes

enum VoidSize {
    static let row: CGFloat = 94
    static let tile: CGFloat = 52
    static let tileHero: CGFloat = 76
    static let tileStreak: CGFloat = 64
    static let badge: CGFloat = 20
    static let pill: CGFloat = 44
    static let cta: CGFloat = 50
    static let start: CGFloat = 200
    static let tabBar: CGFloat = 53
    static let tabItem: CGFloat = 47
    static let statTile: CGFloat = 124
    static let control: CGFloat = 32
    static let chip: CGFloat = 28
    static let listRow: CGFloat = 66
    static let avatar: CGFloat = 36
    static let createTile: CGFloat = 76
    static let hitMin: CGFloat = 44
    static let iconStroke: CGFloat = 2.2
    static let upNextMark = CGSize(width: 3, height: 36)
    static let grabber = CGSize(width: 36, height: 5)
}

// MARK: - Radii (Void is squared: panels, never pills)

enum VoidRadius {
    static let badge: CGFloat = 5, mark: CGFloat = 6, control: CGFloat = 8, avatar: CGFloat = 10, tile: CGFloat = 12
    static let panel: CGFloat = 14, tabBar: CGFloat = 16, tabItem: CGFloat = 13, tileHero: CGFloat = 18, start: CGFloat = 28
}

// MARK: - Glyphs (SF Symbols)

/// The Void glyph vocabulary, backed by SF Symbols — the icon set the app already uses.
enum VoidIcon: String {
    // UI glyphs
    case flame = "flame.fill"
    case flameOutline = "flame"
    case medal = "medal"
    case calendarCheck = "calendar.badge.checkmark"
    case scale = "scalemass"
    case barbell = "dumbbell"
    case check = "checkmark"
    case play = "play.fill"
    case chevron = "chevron.right"
    case more = "ellipsis"
    case sparkle = "sparkles"
    case list = "list.bullet"
    case plus = "plus"
    case link = "link"
    case person = "person"
    case rest = "moon"
    case close = "xmark"
    case back = "chevron.left"
    case share = "square.and.arrow.up"
    case trash = "trash"
    case pause = "pause"
    case restart = "arrow.counterclockwise"
    case swap = "arrow.triangle.2.circlepath"
    case library = "list.bullet.clipboard"
    case edit = "pencil"
    case archive = "archivebox"
    case search = "magnifyingglass"
    case clock = "clock"
    case video = "play.rectangle"
    // Tab glyphs
    case tabToday = "circle.circle"
    case tabPlan = "calendar"
    case tabProgress = "chart.bar.fill"
    // Workout glyphs
    case workoutPush = "figure.strengthtraining.traditional"
    case workoutPull = "figure.strengthtraining.functional"
    case workoutLegs = "figure.walk"
    case workoutLower = "figure.step.training"
    case workoutUpper = "figure.arms.open"
    case workoutFullBody = "figure.cross.training"
    case workoutCore = "figure.core.training"
    case workoutCardio = "figure.run"
    case workoutDefault = "dumbbell.fill"

    var systemName: String { rawValue }
    var image: Image { Image(systemName: rawValue) }

    /// Picks a workout glyph from a template / day name. The tile carries state; the glyph never changes.
    static func workoutGlyph(for name: String?) -> VoidIcon {
        let n = (name ?? "").lowercased()
        if n.contains("push") || n.contains("chest") || n.contains("bench") { return .workoutPush }
        if n.contains("pull") || n.contains("back") || n.contains("row") { return .workoutPull }
        if n.contains("leg") || n.contains("quad") || n.contains("squat") || n.contains("hamstring") || n.contains("glute") { return .workoutLegs }
        if n.contains("lower") { return .workoutLower }
        if n.contains("upper") || n.contains("shoulder") || n.contains("arm") { return .workoutUpper }
        if n.contains("full") || n.contains("total") { return .workoutFullBody }
        if n.contains("core") || n.contains("ab") { return .workoutCore }
        if n.contains("cardio") || n.contains("run") || n.contains("condition") { return .workoutCardio }
        return .workoutDefault
    }
}

// MARK: - Text modifiers

extension View {
    /// Screen eyebrow: Chakra Petch 12, uppercase, tracking .12em.
    func voidEyebrow(_ color: Color = VoidColor.text2) -> some View {
        self.font(VoidFont.eyebrow).tracking(VoidFont.Tracking.eyebrow).textCase(.uppercase).foregroundStyle(color)
    }
    /// Row eyebrow: Chakra Petch 11, uppercase, tracking .12em.
    func voidEyebrowSm(_ color: Color = VoidColor.text2) -> some View {
        self.font(VoidFont.eyebrowSm).tracking(VoidFont.Tracking.eyebrowSm).textCase(.uppercase).foregroundStyle(color)
    }
    /// Readout: Chakra Petch 13, uppercase, tracking .06em.
    func voidReadout(_ color: Color = VoidColor.text2) -> some View {
        self.font(VoidFont.readout).tracking(VoidFont.Tracking.readout).textCase(.uppercase).foregroundStyle(color)
    }
    /// Chip label: Chakra Petch 12, uppercase, tracking .06em (streak chip, segmented control).
    func voidChipLabel(_ color: Color = VoidColor.text) -> some View {
        self.font(VoidFont.eyebrow).tracking(12 * 0.06).textCase(.uppercase).foregroundStyle(color)
    }
    /// Display word: Michroma, uppercase, tracking .02em. `size` must match the font's point size.
    func voidDisplay(_ font: Font, size: CGFloat, color: Color = VoidColor.text) -> some View {
        self.font(font).tracking(VoidFont.Tracking.display(size: size)).textCase(.uppercase).foregroundStyle(color)
    }
    /// The one big word on a screen (Michroma 44).
    func voidWordHero(_ color: Color = VoidColor.text) -> some View {
        voidDisplay(VoidFont.wordHero, size: 44, color: color)
    }
    /// Plan row word (Michroma 30).
    func voidWordRow(_ color: Color = VoidColor.text) -> some View {
        voidDisplay(VoidFont.wordRow, size: 30, color: color)
    }
    /// Big number (Michroma 48). Numbers are not tracked.
    func voidNumberHero(_ color: Color = VoidColor.text) -> some View {
        self.font(VoidFont.numberHero).foregroundStyle(color)
    }
    /// Stat-tile number (Michroma 24).
    func voidNumber(_ color: Color = VoidColor.text) -> some View {
        self.font(VoidFont.number).foregroundStyle(color)
    }
}
