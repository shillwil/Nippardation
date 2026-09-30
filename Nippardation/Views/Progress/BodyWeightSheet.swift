//
//  BodyWeightSheet.swift
//  Nippardation
//
//  Sheet behind the BODY LB stat tile: log a weight in pounds and review or delete
//  recent entries. A standard form sheet: Cancel / Log in the navigation bar, the weight
//  field in its own section, recent entries below with swipe to delete.
//  Backed by `BodyWeightStore.shared`.
//

import SwiftUI

struct BodyWeightSheet: View {
    @ObservedObject private var store = BodyWeightStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    /// The most recent entries shown under the field.
    private static let recentLimit = 5

    private var recentEntries: [BodyWeightEntry] {
        Array(store.entries.prefix(Self.recentLimit))
    }

    /// Accepts "182.4" or "182,4"; rejects zero, negatives and nonsense.
    private var parsedPounds: Double? {
        let normalized = input
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(normalized), value.isFinite, value > 0, value < 1500 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: VoidSpace.s3) {
                        TextField("Body weight", text: $input, prompt: Text("0.0"))
                            .keyboardType(.decimalPad)
                            .font(VoidFont.body)
                            .foregroundStyle(VoidColor.text)
                            .focused($isInputFocused)
                            .accessibilityLabel("Body weight in pounds")
                        Text("LB")
                            .voidReadout()
                            .accessibilityHidden(true)
                    }
                }

                if !recentEntries.isEmpty {
                    Section {
                        ForEach(recentEntries) { entry in
                            LabeledContent {
                                Text("\(VoidFormat.weight(entry.pounds)) LB")
                                    .voidReadout(VoidColor.text)
                            } label: {
                                Text(VoidFormat.relativeDay(entry.date).capitalized)
                                    .font(VoidFont.body)
                                    .foregroundStyle(VoidColor.text)
                            }
                        }
                        .onDelete(perform: delete)
                    } header: {
                        Text("Recent")
                    }
                }
            }
            .navigationTitle("Body weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel, not Close: dismissing throws away a typed weight.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        log()
                    }
                    .disabled(parsedPounds == nil)
                }
                // The decimal pad has no return key.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Actions

    private func log() {
        guard let pounds = parsedPounds else { return }
        store.log(pounds: pounds)
        input = ""
        isInputFocused = false
        dismiss()
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.compactMap { recentEntries.indices.contains($0) ? recentEntries[$0].id : nil }
        ids.forEach { store.delete(id: $0) }
    }
}

// MARK: - Previews

#Preview("Body weight") {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        Color.clear
            .sheet(isPresented: .constant(true)) {
                BodyWeightSheet()
            }
    }
}
