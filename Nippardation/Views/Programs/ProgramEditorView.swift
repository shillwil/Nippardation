//
//  ProgramEditorView.swift
//  Nippardation
//
//  Edit plan: rename, set the length, reorder days, add or remove a day, assign a workout to a day.
//  Void list panels instead of a system Form; the ViewModel's save() contract is unchanged.
//

import SwiftUI

struct ProgramEditorView: View {

    @StateObject private var viewModel: ProgramEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showTemplatePicker = false
    @State private var selectedWorkoutIndex: Int?

    /// Fired with the saved plan just before the editor dismisses itself.
    private let onSaved: ((Program) -> Void)?

    init(existingProgram: Program? = nil, onSaved: ((Program) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: ProgramEditorViewModel(existingProgram: existingProgram))
        self.onSaved = onSaved
    }

    private enum PlanLength: Hashable {
        case ongoing
        case weeks

        var label: String {
            switch self {
            case .ongoing: return "Ongoing"
            case .weeks: return "Weeks"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            nameSection
            lengthSection
            daysSection
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(VoidSpace.s5)
        .environment(\.defaultMinListRowHeight, 52)
        .voidScreen()
        .navigationTitle(viewModel.isEditing ? "Edit plan" : "New plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: VoidSpace.s3) {
                    EditButton()
                    Button("Save") {
                        viewModel.save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid || !viewModel.isStep2Valid || viewModel.isSaving)
                }
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplateSelectorSheet(
                templates: viewModel.availableTemplates,
                isLoading: viewModel.isLoadingTemplates,
                onSelect: { template in
                    if let index = selectedWorkoutIndex {
                        viewModel.setTemplate(template, for: index)
                    }
                }
            )
        }
        .onChange(of: viewModel.savedProgram) { _, newValue in
            if let program = newValue {
                onSaved?(program)
                dismiss()
            }
        }
        .onAppear {
            viewModel.loadTemplates()
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
        .alert("Something went wrong", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error ?? "An unknown error occurred")
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            VoidTextField(placeholder: "Plan name", text: $viewModel.name, autocapitalization: .words)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } header: {
            sectionHeader("Name")
        }
    }

    private var lengthSection: some View {
        Section {
            HStack {
                Text(viewModel.isIndefinite ? "Ongoing" : "\(viewModel.durationWeeks ?? 8) weeks")
                    .font(VoidFont.body)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
                Spacer()
                VoidSegmentedControl(
                    items: [PlanLength.ongoing, PlanLength.weeks],
                    label: { $0.label },
                    selection: lengthSelection
                )
            }
            .listRowBackground(VoidColor.panel)
            .listRowSeparatorTint(VoidColor.hairline)

            if !viewModel.isIndefinite {
                HStack {
                    Text("Weeks")
                        .font(VoidFont.body)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Spacer()
                    PlanStepperWell(value: weeksBinding, range: 1...52)
                }
                .listRowBackground(VoidColor.panel)
                .listRowSeparatorTint(VoidColor.hairline)
            }
        } header: {
            sectionHeader("Length")
        }
    }

    private var daysSection: some View {
        Section {
            ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                dayRow(workout, index: index)
            }
            .onMove { source, destination in
                viewModel.moveWorkouts(from: source, to: destination)
            }
            .onDelete { offsets in
                viewModel.removeWorkouts(at: offsets)
            }

            if viewModel.canAddWorkout {
                addDayRow
            }
        } header: {
            HStack {
                Text("Days").voidEyebrowSm()
                Spacer()
                Text(VoidFormat.pad2(viewModel.workouts.count)).voidEyebrowSm()
            }
        } footer: {
            if viewModel.workouts.isEmpty {
                Text("Add at least one day.")
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
            } else if !allDaysAssigned {
                Text("Choose a workout for every day.")
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).voidEyebrowSm()
    }

    // MARK: - Rows

    private func dayRow(_ workout: ProgramEditorViewModel.EditableWorkout, index: Int) -> some View {
        Button {
            selectedWorkoutIndex = index
            showTemplatePicker = true
        } label: {
            HStack(spacing: VoidSpace.s3) {
                VStack(alignment: .leading, spacing: VoidSpace.s1) {
                    Text("Day \(VoidFormat.pad2(index + 1))")
                        .voidEyebrowSm()
                    Text(workout.templateName ?? "Choose workout")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(workout.templateName == nil ? VoidColor.text2 : VoidColor.text)
                        .lineLimit(1)
                }
                Spacer(minLength: VoidSpace.s2)
                VoidChevron()
            }
            .padding(.vertical, VoidSpace.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
        // A plan needs at least one day; the last row cannot be swiped away.
        .deleteDisabled(viewModel.workouts.count <= 1)
        .accessibilityLabel("Day \(index + 1), \(workout.templateName ?? "no workout chosen")")
        .accessibilityHint("Choose a workout")
    }

    private var addDayRow: some View {
        Button {
            viewModel.addWorkout()
        } label: {
            HStack(spacing: VoidSpace.s3) {
                Image(systemName: VoidIcon.plus.systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(VoidColor.text)
                    .frame(width: 20)
                Text("Add a day")
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                Spacer()
            }
            .padding(.vertical, VoidSpace.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
        .deleteDisabled(true)
        .moveDisabled(true)
    }

    private var savingOverlay: some View {
        ZStack {
            VoidColor.hull.opacity(0.6).ignoresSafeArea()
            VStack(spacing: VoidSpace.s3) {
                ProgressView()
                    .tint(VoidColor.text)
                Text("Saving").voidEyebrowSm()
            }
            .padding(VoidSpace.s6)
            .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline2)
        }
    }

    // MARK: - Bindings & derived

    private var lengthSelection: Binding<PlanLength> {
        Binding(
            get: { viewModel.isIndefinite ? .ongoing : .weeks },
            set: { viewModel.isIndefinite = ($0 == .ongoing) }
        )
    }

    private var weeksBinding: Binding<Int> {
        Binding(
            get: { viewModel.durationWeeks ?? 8 },
            set: { viewModel.durationWeeks = $0 }
        )
    }

    private var allDaysAssigned: Bool {
        viewModel.workouts.enumerated().allSatisfy { index, workout in
            viewModel.restDays.contains(index) || workout.templateServerId != nil
        }
    }
}

// MARK: - Stepper well

/// Squared −/+ stepper: panel-2 well, radius 8, SF 20 bold monospaced value.
/// Each button is a full `VoidSize.hitMin` square so the well meets the 44pt hit target inside a 52pt row.
/// The minus glyph is not part of `VoidIcon`; it is the one SF Symbol named here directly.
private struct PlanStepperWell: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    private static let minusSymbol = "minus"

    var body: some View {
        HStack(spacing: 0) {
            step(symbol: Self.minusSymbol, enabled: value > range.lowerBound, label: "Fewer weeks") {
                value = max(range.lowerBound, value - 1)
            }
            Text(VoidFormat.pad2(value))
                .font(VoidFont.stepper)
                .foregroundStyle(VoidColor.text)
                .frame(minWidth: 44)
            step(symbol: VoidIcon.plus.systemName, enabled: value < range.upperBound, label: "More weeks") {
                value = min(range.upperBound, value + 1)
            }
        }
        .voidPanel(radius: VoidRadius.control, line: VoidColor.hairline2, fill: VoidColor.panel2)
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(value) weeks")
    }

    private func step(symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(VoidColor.text)
                .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

// MARK: - Previews

#Preview("New plan") {
    NavigationStack {
        ProgramEditorView()
    }
    .withDependencies(.preview)
}

#Preview("Edit plan") {
    NavigationStack {
        ProgramEditorView(existingProgram: MockProgramRepository.samplePrograms[1])
    }
    .withDependencies(.preview)
}
