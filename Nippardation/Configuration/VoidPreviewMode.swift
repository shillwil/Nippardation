//
//  VoidPreviewMode.swift
//  Nippardation
//
//  DEBUG-only launch mode for looking at the app with mock data and no sign-in:
//    xcrun simctl launch booted com.shillwil.recess-fitness --void-preview [--void-tab plan] [--void-empty] [--void-share]
//  Never compiled into Release builds.
//

import Foundation

#if DEBUG
enum VoidPreviewMode {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    /// `--void-preview` — show MainTabView with mock repositories, skipping authentication.
    static var isEnabled: Bool { arguments.contains("--void-preview") }

    /// `--void-tab today|plan|progress`
    static var initialTab: AppTab? {
        guard let index = arguments.firstIndex(of: "--void-tab"), index + 1 < arguments.count else { return nil }
        return AppTab(rawValue: arguments[index + 1])
    }

    /// `--void-empty` — deactivate the mock's active plan so the empty states show.
    static var wantsEmptyPlan: Bool { arguments.contains("--void-empty") }

    /// `--void-share` — open the received-plan sheet with the mock share.
    static var wantsSharedPlan: Bool { arguments.contains("--void-share") }

    @MainActor
    static func configure() {
        guard isEnabled else { return }
        DependencyContainer.shared.configureForTesting()
        if wantsEmptyPlan {
            Task { try? await DependencyContainer.shared.programRepository.deactivateProgram() }
        }
        if wantsSharedPlan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                DeepLinkRouter.shared.open(token: "mock_abc123")
            }
        }
    }
}
#endif
