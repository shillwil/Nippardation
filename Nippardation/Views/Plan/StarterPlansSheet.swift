//
//  StarterPlansSheet.swift
//  Nippardation
//
//  The five built-in splits. Picking one builds real workouts + a plan on the backend,
//  activates it, and hands the plan back so the presenter can land on Today.
//

import SwiftUI

struct StarterPlansSheet: View {
    /// Called after the plan is built and activated; the sheet has already dismissed itself.
    var onBuilt: (Program) -> Void = { _ in }

    @StateObject private var builder = StarterPlanBuilder()
    @Environment(\.dismiss) private var dismiss

    private let splits = StarterPlanBuilder.splits

    var body: some View {
        ScrollView {
            VoidSheetContainer {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Starter splits").voidEyebrow()

                    Text("Workouts from the built-in lists, matched to the exercise library.")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .padding(.top, 6)

                    panel
                        .padding(.top, 18)

                    if builder.isBuilding {
                        HStack(spacing: 10) {
                            ProgressView().tint(VoidColor.plasma)
                            Text(builder.progressText).voidEyebrowSm()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .voidSheet()
        .presentationDetents([.fraction(0.6), .large])
        .interactiveDismissDisabled(builder.isBuilding)
        .alert("Could not build this plan", isPresented: Binding(
            get: { builder.error != nil },
            set: { if !$0 { builder.error = nil } }
        )) {
            Button("OK") { builder.error = nil }
        } message: {
            Text(builder.error ?? "")
        }
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(spacing: 0) {
            ForEach(Array(splits.enumerated()), id: \.element.id) { index, split in
                row(split)
                if index < splits.count - 1 {
                    VoidHairline()
                }
            }
        }
        .padding(.horizontal, 14)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
        .opacity(builder.isBuilding ? 0.5 : 1)
        .disabled(builder.isBuilding)
    }

    private func row(_ split: StarterSplit) -> some View {
        Button {
            pick(split)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(split.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text(split.caption)
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Build

    private func pick(_ split: StarterSplit) {
        Task {
            let built = await builder.build(split)
            if built, let program = builder.builtProgram {
                dismiss()
                onBuilt(program)
            }
        }
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
    }
    .sheet(isPresented: .constant(true)) {
        StarterPlansSheet()
            .environmentObject(AppNavigation())
    }
    .withDependencies(.preview)
}
