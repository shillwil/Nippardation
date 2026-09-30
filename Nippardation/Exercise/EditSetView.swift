//
//  EditSetView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//
//  "Edit set" sheet: the Add set form (rows in `SetEntryForm.swift`) under a navigation bar
//  (Cancel / Save), filled with the set being edited. Weight is typed on the decimal pad or
//  stepped in place, with no separate weight sheet; the typed weight is read on Save.
//

import SwiftUI

// Edit Set View for modifying existing sets
struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var setType: SetType
    var onSave: (Int, Double, SetType) -> Void
    
    @State private var weightString: String = ""
    @FocusState private var isWeightFocused: Bool
    
    init(reps: Binding<Int>, weight: Binding<Double>, setType: Binding<SetType>, onSave: @escaping (Int, Double, SetType) -> Void) {
        self._reps = reps
        self._weight = weight
        self._setType = setType
        self.onSave = onSave
        self._weightString = State(initialValue: SetEntry.weightText(weight.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SetTypePicker(setType: $setType)
                    SetRepsStepper(reps: $reps)
                }

                SetWeightSection(weight: $weight, text: $weightString, isFocused: $isWeightFocused)
            }
            .listSectionSpacing(.compact)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Dismissing drops the edit, so this is Cancel rather than Close.
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSet()
                    }
                    .disabled(!canSave)
                }
                // The decimal pad has no return key.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isWeightFocused = false
                    }
                }
            }
        }
        .tint(VoidColor.plasmaInk)
    }

    /// Save stays off until there's a weight in range to save.
    private var canSave: Bool {
        SetEntry.weightToSave(text: weightString, weight: weight) != nil
    }

    /// The typed weight is read here, not on focus loss, so a number still being typed is kept.
    /// A weight the text still shows (not typed over, or stepped) is saved as it is, so a Save
    /// that only changes the reps or set type leaves the logged weight exactly as it was.
    private func saveSet() {
        guard let enteredWeight = SetEntry.weightToSave(text: weightString, weight: weight) else { return }
        isWeightFocused = false
        weight = enteredWeight
        onSave(reps, enteredWeight, setType)
        dismiss()
    }
}

#Preview {
    EditSetView(reps: .constant(8), weight: .constant(42.5), setType: .constant(.working)) { _, _,_  in
        
    }
}
