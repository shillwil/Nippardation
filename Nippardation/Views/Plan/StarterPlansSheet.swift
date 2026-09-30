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
        NavigationStack {
            List {
                Section {
                    ForEach(splits) { split in
                        row(split)
                    }
                } footer: {
                    footer
                }
            }
            .listStyle(.insetGrouped)
            // No list or sheet fill of our own, so the system sheet material shows behind the rows.
            .scrollContentBackground(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("Starter splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton { dismiss() }
                        .disabled(builder.isBuilding)
                }
            }
        }
        .tint(VoidColor.plasmaInk)
        .presentationDetents([.fraction(0.6), .large])
        .presentationDragIndicator(.visible)
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

    // MARK: - Rows

    /// Picking a split builds it, so a button row without a chevron.
    private func row(_ split: StarterSplit) -> some View {
        Button {
            pick(split)
        } label: {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(builder.isBuilding ? 0.5 : 1)
        }
        .disabled(builder.isBuilding)
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
    }

    /// What the splits are, and while one is building, how far along it is.
    private var footer: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            Text("Workouts from the built-in lists, matched to the exercise library.")
            if builder.isBuilding {
                HStack(spacing: VoidSpace.s2) {
                    ProgressView()
                    Text(builder.progressText)
                }
            }
        }
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
