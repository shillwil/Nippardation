//
//  PlanReceivedSheet.swift
//  Nippardation
//
//  Plan received (HANDOFF screen 5): the deep-link landing sheet. Presented by MainTabView
//  over whatever is up. Fetches the share, shows the week strip, and offers Use this plan /
//  Preview workouts / Save for later.
//

import SwiftUI

struct PlanReceivedSheet: View {
    let token: String
    let onDismiss: () -> Void

    @StateObject private var viewModel: ReceivedPlanViewModel
    @EnvironmentObject private var navigation: AppNavigation
    @State private var route: Route?
    @State private var didLoad = false

    private enum Route: Hashable {
        case plan(Program)
        case workout(Template)
    }

    init(token: String, onDismiss: @escaping () -> Void) {
        self.token = token
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: ReceivedPlanViewModel(token: token))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VoidSheetContainer {
                    content
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(VoidColor.panel)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $route) { route in
                switch route {
                case .plan(let program):
                    PlanPreviewView(program: program, isShared: true)
                case .workout(let template):
                    WorkoutPreviewView(template: template)
                }
            }
        }
        .tint(VoidColor.plasma)
        .voidSheet()
        .presentationDetents([.fraction(0.62), .large])
        .interactiveDismissDisabled(viewModel.state == .importing)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.item != nil {
            loadedView
        } else if case .error(let message) = viewModel.state {
            errorView(message)
        } else {
            loadingView
        }
    }

    // MARK: - Loaded

    private var loadedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.senderEyebrow)
                .voidEyebrow(VoidColor.warning)
                .lineLimit(1)

            Text(viewModel.title)
                .voidWordRow()
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 8)

            Text(viewModel.readout)
                .voidReadout()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 6)

            dayStrip
                .padding(.top, 18)

            VoidCTAButton(title: viewModel.ctaTitle, isLoading: viewModel.state == .importing) {
                use()
            }
            .padding(.top, 24)

            HStack(spacing: 10) {
                VoidPillButton(title: viewModel.isProgram ? "Preview workouts" : "Preview workout") {
                    preview()
                }
                VoidPillButton(title: viewModel.isSaved ? "Saved" : "Save for later", isEnabled: !viewModel.isSaved) {
                    save()
                }
            }
            .padding(.top, 10)

            if let importError {
                Text(importError)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.warning)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }

            Text("Saved plans wait under Plan → Sent to you. Your history is never changed.")
                .font(VoidFont.caption2)
                .foregroundStyle(VoidColor.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
    }

    private var importError: String? {
        if case .error(let message) = viewModel.state, viewModel.item != nil {
            return message
        }
        return nil
    }

    /// MON…SUN: raised tiles on training days, ghost squares on rest days. Seven 52pt tiles
    /// do not fit a 353pt sheet, so the strip scales down evenly when it has to.
    private var dayStrip: some View {
        let cells = viewModel.dayCells
        let single = cells.count == 1
        return GeometryReader { geo in
            let count = max(cells.count, 1)
            let spacing: CGFloat = 4
            let available = geo.size.width - spacing * CGFloat(count - 1)
            let scale = min(1, available / (VoidSize.tile * CGFloat(count)))
            HStack(alignment: .top, spacing: spacing) {
                ForEach(cells) { cell in
                    VStack(spacing: 6) {
                        Group {
                            if let glyph = cell.glyph {
                                WorkoutTile(glyph: glyph, raised: true)
                            } else {
                                WorkoutTile(ghost: true)
                            }
                        }
                        .scaleEffect(scale)
                        .frame(width: VoidSize.tile * scale, height: VoidSize.tile * scale)

                        Text(cell.label)
                            .voidEyebrowSm(cell.glyph == nil ? VoidColor.text3 : VoidColor.text2)
                    }
                    .frame(maxWidth: single ? nil : .infinity)
                }
                if single {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: VoidSize.tile + 6 + 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayStripLabel)
    }

    private var dayStripLabel: String {
        let training = viewModel.dayCells.filter { $0.glyph != nil }.map(\.label)
        return training.isEmpty ? "No training days" : "Training days: \(training.joined(separator: ", "))"
    }

    // MARK: - Loading / error

    private var loadingView: some View {
        VStack(spacing: 8) {
            Text("Sent to you").voidEyebrow(VoidColor.warning)
            ProgressView()
                .tint(VoidColor.plasma)
                .padding(.top, 24)
            Text("Loading plan…")
                .font(VoidFont.caption2)
                .foregroundStyle(VoidColor.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VoidSpace.s6)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text("Could not load").voidEyebrow(VoidColor.warning)
            Text(message)
                .font(VoidFont.caption2)
                .foregroundStyle(VoidColor.text2)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                VoidPillButton(title: "Try again") { viewModel.retry() }
                VoidPillButton(title: "Close") { onDismiss() }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VoidSpace.s4)
    }

    // MARK: - Actions

    private func use() {
        Task {
            guard await viewModel.use() else { return }
            if viewModel.isProgram {
                navigation.planDidChange()
                onDismiss()
                navigation.show(.today)
            } else {
                onDismiss()
            }
        }
    }

    private func preview() {
        guard let item = viewModel.item else { return }
        if item.type == .program, let program = item.program {
            route = .plan(program)
        } else if let template = item.template {
            route = .workout(template)
        }
    }

    private func save() {
        viewModel.saveForLater()
        onDismiss()
    }
}

// MARK: - Previews

#Preview("Loaded") {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        Text("Today").voidEyebrow()
    }
    .sheet(isPresented: .constant(true)) {
        PlanReceivedSheet(token: "mock_abc123") { }
            .environmentObject(AppNavigation())
    }
    .withDependencies(.preview)
}
