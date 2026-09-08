//
//  BodyWeightSheet.swift
//  Nippardation
//
//  Bottom sheet behind the BODY LB stat tile: log a weight in pounds and
//  review or delete recent entries. Backed by `BodyWeightStore.shared`.
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
        VoidSheetContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Body weight")
                    .voidEyebrow()

                HStack(spacing: 10) {
                    VoidTextField(
                        placeholder: "0.0",
                        text: $input,
                        icon: .scale,
                        keyboard: .decimalPad
                    )
                    .focused($isInputFocused)
                    .accessibilityLabel("Body weight in pounds")

                    Text("LB")
                        .voidReadout()
                }
                .padding(.top, VoidSpace.s3)

                VoidCTAButton(title: "Log", isEnabled: parsedPounds != nil) {
                    log()
                }
                .padding(.top, VoidSpace.s3)

                if !recentEntries.isEmpty {
                    Text("Recent")
                        .voidEyebrowSm()
                        .padding(.top, VoidSpace.s6)
                        .padding(.bottom, VoidSpace.s2)

                    recentList
                        .frame(maxHeight: .infinity)
                }
            }
            // Pin to the top so the grabber sits at the edge even before the first entry
            // exists; with entries the list still fills the rest of the sheet.
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .voidSheet()
        .presentationDetents([.medium, .large])
        .onAppear {
            isInputFocused = true
        }
    }

    /// Plain list so rows keep swipe-to-delete; chrome is hidden and rows draw their own hairlines.
    private var recentList: some View {
        List {
            ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                VStack(spacing: 0) {
                    HStack {
                        Text(VoidFormat.relativeDay(entry.date).capitalized)
                            .font(VoidFont.body)
                            .foregroundStyle(VoidColor.text)
                        Spacer()
                        Text("\(VoidFormat.weight(entry.pounds)) LB")
                            .voidReadout(VoidColor.text)
                    }
                    .frame(height: VoidSize.pill)
                    if index < recentEntries.count - 1 {
                        VoidHairline()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityElement(children: .combine)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, VoidSize.pill)
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
