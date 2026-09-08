//
//  VoidTabBar.swift
//  Nippardation
//
//  The three-tab floating bar: Today · Plan · Progress. Replaces TabBarConfiguration.
//  53pt tall, radius 16, `tabBar` fill, inner .5pt line, 0 8 24 black .6 shadow, blur behind.
//  Items 47pt, radius 13; active = panel-2 fill + text; inactive = text-2.
//  The active glyph carries a plasma pip. Tab switching has no animation.
//

import SwiftUI

/// The three bottom tabs.
enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case today
    case plan
    case progress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .plan: return "Plan"
        case .progress: return "Progress"
        }
    }

    var icon: VoidIcon {
        switch self {
        case .today: return .tabToday
        case .plan: return .tabPlan
        case .progress: return .tabProgress
        }
    }
}

/// App-wide navigation state shared through the environment so any screen can switch tabs.
@MainActor
final class AppNavigation: ObservableObject {
    @Published var selectedTab: AppTab = .today

    init() {
        #if DEBUG
        if let tab = VoidPreviewMode.initialTab { selectedTab = tab }
        #endif
    }

    /// Bumps whenever something that Today/Plan should reload from changed (plan activated, import, etc.).
    @Published var planRevision: Int = 0

    func show(_ tab: AppTab) {
        selectedTab = tab
    }

    func planDidChange() {
        planRevision &+= 1
    }
}

struct VoidTabBar: View {
    @Binding var selection: AppTab
    /// Draws a plasma dot on the Plan tab while there is an unread received plan.
    var showsPlanDot: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                item(tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(height: VoidSize.tabBar)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(VoidColor.tabBar)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tabBar, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VoidRadius.tabBar, style: .continuous)
                .strokeBorder(VoidColor.tabBarLine, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func item(_ tab: AppTab) -> some View {
        let on = tab == selection
        Button {
            // Instant swap. No haptic on tab change.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                glyph(tab, active: on)
                Text(tab.label)
                    .font(VoidFont.tab)
            }
            .foregroundStyle(on ? VoidColor.text : VoidColor.text2)
            .frame(maxWidth: .infinity)
            .frame(height: VoidSize.tabItem)
            .background(on ? VoidColor.panel2 : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tabItem, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .accessibilityHint(tab == .plan && showsPlanDot ? "New plan received" : "")
    }

    @ViewBuilder
    private func glyph(_ tab: AppTab, active: Bool) -> some View {
        ZStack {
            Image(systemName: tab.icon.systemName)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 24, height: 24)

            if active {
                pip(tab)
            }

            if tab == .plan && showsPlanDot {
                PlasmaDot(size: 6)
                    .offset(x: 12, y: -11)
            }
        }
        .frame(width: 24, height: 24)
    }

    /// The plasma pip drawn inside the active glyph.
    @ViewBuilder
    private func pip(_ tab: AppTab) -> some View {
        switch tab {
        case .today:
            Circle().fill(VoidColor.plasma).frame(width: 7, height: 7)
        case .plan:
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(VoidColor.plasma)
                .frame(width: 4.5, height: 4.5)
                .offset(x: -5, y: 3)
        case .progress:
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(VoidColor.plasma)
                .frame(width: 4.5, height: 15)
                .offset(x: 6.5, y: 1)
        }
    }
}

/// Geometry shared by the bar overlay and the per-page clearance.
/// The bar sits on the bottom safe-area inset (home indicator) where there is one, else 19pt from the edge.
enum VoidTabBarMetrics {
    @MainActor static var homeIndicatorInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        let window = windows.first { $0.isKeyWindow } ?? windows.first
        return window?.safeAreaInsets.bottom ?? 0
    }

    /// Extra padding under the bar on devices without a home indicator.
    @MainActor static var bottomPadding: CGFloat {
        homeIndicatorInset > 0 ? 0 : 19
    }

    /// How much of the bottom of a page the bar covers, measured from the page's safe-area bottom.
    @MainActor static var clearance: CGFloat {
        VoidSize.tabBar + bottomPadding
    }
}

/// Draws the floating tab bar over the wrapped content (a `TabView`), sitting on the bottom safe area.
/// Insets 19 left / 16 right, and 19 bottom on devices without a home indicator.
/// Pair with `voidTabBarClearance()` on each page: the pages are UIKit-hosted and do not inherit a
/// SwiftUI `safeAreaInset` from their parent, so the clearance is applied at the UIKit level.
/// The bar ignores the keyboard safe-area region so it stays anchored on the home-indicator edge,
/// beneath the keyboard, like `UITabBar` does — it never rides up on top of the keyboard.
struct VoidTabBarOverlay: ViewModifier {
    @Binding var selection: AppTab
    var showsPlanDot: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                VoidTabBar(selection: $selection, showsPlanDot: showsPlanDot)
                    .padding(.leading, 19)
                    .padding(.trailing, 16)
                    .padding(.bottom, VoidTabBarMetrics.bottomPadding)
            }
            // The keyboard shrinks the root safe area, which would lift the bar (and the pages' clearance)
            // onto the keyboard. Ignoring only the keyboard region here keeps the bar on the home-indicator
            // edge; the UIKit-hosted pages still avoid the keyboard through their own hosting controllers.
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/// Reserves the bar's height at the bottom of a page so its content (and bottom pills) clear the bar,
/// on the root and on every pushed screen, but not on sheets or full-screen covers.
struct VoidTabBarClearance: ViewModifier {
    func body(content: Content) -> some View {
        content.background(VoidSafeAreaReserver(bottom: VoidTabBarMetrics.clearance))
    }
}

/// Adds `additionalSafeAreaInsets.bottom` to the nearest tab / navigation controller so UIKit-hosted
/// SwiftUI pages lay out above the floating bar.
struct VoidSafeAreaReserver: UIViewControllerRepresentable {
    let bottom: CGFloat

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.bottom = bottom
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.bottom = bottom
        controller.apply()
    }

    final class Controller: UIViewController {
        var bottom: CGFloat = 0

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            apply()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
            paintWindow()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // `view.window` is reliably set by now (it can still be nil in viewWillAppear).
            paintWindow()
        }

        /// The window shows behind the scaled-down presenter under a `.large` sheet and during
        /// full-screen-cover transitions; paint it hull so light mode does not show black there.
        private func paintWindow() {
            view.window?.backgroundColor = VoidColor.hullUIColor
        }

        func apply() {
            var ancestor = parent
            var navigation: UINavigationController?
            var tabs: UITabBarController?
            while let current = ancestor {
                if navigation == nil, let nav = current as? UINavigationController { navigation = nav }
                if let tab = current as? UITabBarController { tabs = tab }
                ancestor = current.parent
            }
            // Prefer the tab controller (one place, every tab); fall back to the navigation controller.
            if let tabs {
                if tabs.additionalSafeAreaInsets.bottom != bottom {
                    tabs.additionalSafeAreaInsets.bottom = bottom
                }
            } else if let navigation, navigation.additionalSafeAreaInsets.bottom != bottom {
                navigation.additionalSafeAreaInsets.bottom = bottom
            }
        }
    }
}

extension View {
    /// Overlay the floating tab bar on a container. Apply `voidTabBarClearance()` to each page.
    func voidTabBar(selection: Binding<AppTab>, showsPlanDot: Bool = false) -> some View {
        modifier(VoidTabBarOverlay(selection: selection, showsPlanDot: showsPlanDot))
    }

    /// Reserve space for the floating tab bar at the bottom of a page.
    func voidTabBarClearance() -> some View {
        modifier(VoidTabBarClearance())
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 16) {
            VoidTabBar(selection: .constant(.today))
            VoidTabBar(selection: .constant(.plan), showsPlanDot: true)
            VoidTabBar(selection: .constant(.progress))
        }
        .padding(.leading, 19)
        .padding(.trailing, 16)
        .padding(.bottom, 19)
    }
}
