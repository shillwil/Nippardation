//
//  SetEntryForm.swift
//  Nippardation
//
//  Shared by the Add set and Edit set sheets: the rules a set has to meet (rep and weight
//  ranges, the weight step sizes, how weight is shown, read and saved) and the form rows, all
//  system controls: a segmented set-type Picker, a reps Stepper, and the weight section (a
//  decimal-pad TextField, a Stepper that moves it by the chosen step, and the step sizes as a
//  segmented Picker).
//

import SwiftUI

// MARK: - Rules

/// Ranges, weight step sizes and weight text for the set-entry sheets. Weight is in lbs.
enum SetEntry {
    /// Reps a set can hold: the reps stepper's range.
    static let repsRange: ClosedRange<Int> = 1...999
    /// Weight a set can hold, in lbs: the weight stepper's range and the check on typed weight.
    static let weightRange: ClosedRange<Double> = 0...2000
    /// Step sizes for the weight stepper, in lbs.
    static let weightIncrements: [Double] = [2.5, 5.0, 10.0, 25.0, 45.0]
    /// The step size a sheet opens with.
    static let defaultWeightIncrement: Double = 5.0

    /// Formats weight text with ASCII digits and "." before the region's separator goes in.
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// Weight as the text field shows it: one decimal, or two when the weight has them ("135.0",
    /// "46.25"), so a weight typed to the hundredth reads back unchanged. Uses the region's
    /// decimal separator ("46,25" in much of Europe) but always ASCII digits, which
    /// `weight(from:)` reads in every region.
    static func weightText(_ weight: Double, locale: Locale = .current) -> String {
        let text = weight.formatted(
            .number.precision(.fractionLength(1...2)).grouping(.never).locale(posixLocale)
        )
        guard let separator = locale.decimalSeparator, separator != "." else { return text }
        return text.replacingOccurrences(of: ".", with: separator)
    }

    /// Reads typed weight. Accepts "." and the region's decimal separator, which is the one the
    /// decimal pad offers ("," in much of Europe). Nil unless the text is a finite number.
    static func weight(from text: String, locale: Locale = .current) -> Double? {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let separator = locale.decimalSeparator, separator != "." {
            normalized = normalized.replacingOccurrences(of: separator, with: ".")
        }
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }

    /// Typed weight that can be saved: a number inside `weightRange`, otherwise nil.
    static func validWeight(from text: String, locale: Locale = .current) -> Double? {
        guard let value = weight(from: text, locale: locale), weightRange.contains(value) else { return nil }
        return value
    }

    /// The weight a sheet saves. While the text still shows `weight` (never typed over, or just
    /// stepped) that's `weight` itself, so a weight with more decimals than the field shows isn't
    /// rounded by a Save that only changed the reps or set type. Otherwise it's the typed weight.
    /// Nil unless the weight is inside `weightRange`.
    static func weightToSave(text: String, weight: Double, locale: Locale = .current) -> Double? {
        if weightRange.contains(weight), text == weightText(weight, locale: locale) {
            return weight
        }
        return validWeight(from: text, locale: locale)
    }

    /// Pins a weight inside `weightRange`.
    static func clampedWeight(_ weight: Double) -> Double {
        min(max(weight, weightRange.lowerBound), weightRange.upperBound)
    }

    /// Step-size label without a trailing ".0": "2.5", "5", "45".
    static func incrementLabel(_ increment: Double) -> String {
        increment.rounded() == increment ? String(Int(increment)) : String(increment)
    }
}

// MARK: - Set type

/// Warm-up or Working, as a system segmented control.
struct SetTypePicker: View {
    @Binding var setType: SetType

    var body: some View {
        Picker("Set type", selection: $setType) {
            Text("Warm-up").tag(SetType.warmup)
            Text("Working").tag(SetType.working)
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Reps

/// Reps row: the count in the stepper font, the system stepper at the trailing edge
/// (press and hold repeats).
struct SetRepsStepper: View {
    @Binding var reps: Int

    var body: some View {
        Stepper(value: $reps, in: SetEntry.repsRange) {
            LabeledContent("Reps") {
                Text(VoidFormat.pad2(reps))
                    .font(VoidFont.stepper)
                    .foregroundStyle(VoidColor.text)
            }
        }
        .accessibilityLabel("Reps")
        .accessibilityValue(String(reps))
    }
}

// MARK: - Weight

/// Weight section. The text is the value: the sheet reads it on Save, so a number still being
/// typed is never dropped, and saves `weight` itself while the text still shows it
/// (`SetEntry.weightToSave`). The stepper starts from what's typed (or the last weight when the
/// text isn't a number), moves it by the chosen step inside `SetEntry.weightRange`, and writes
/// the result to both the text and `weight`. The footer says why Save is off while there's no
/// valid weight to save.
struct SetWeightSection: View {
    @Binding var weight: Double
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding

    @State private var increment = SetEntry.defaultWeightIncrement

    var body: some View {
        Section {
            LabeledContent("Weight") {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField("Weight", text: $text, prompt: Text("0.0"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(VoidFont.stepper)
                        .foregroundStyle(VoidColor.text)
                        .focused(isFocused)
                    Text("lbs")
                        .foregroundStyle(VoidColor.text2)
                }
            }

            Stepper(value: steppedWeight, in: SetEntry.weightRange, step: increment) {
                Text("Adjust by \(SetEntry.incrementLabel(increment)) lbs")
            }
            .accessibilityLabel("Weight")
            .accessibilityValue("\(SetEntry.weightText(currentWeight)) lbs")
            .accessibilityHint("Changes the weight by \(SetEntry.incrementLabel(increment)) lbs")

            Picker("Adjust by", selection: $increment) {
                ForEach(SetEntry.weightIncrements, id: \.self) { step in
                    Text(SetEntry.incrementLabel(step)).tag(step)
                }
            }
            .pickerStyle(.segmented)
        } footer: {
            if SetEntry.weightToSave(text: text, weight: weight) == nil {
                Text("Enter a weight from \(Int(SetEntry.weightRange.lowerBound)) to \(Int(SetEntry.weightRange.upperBound)) lbs.")
            }
        }
    }

    /// The weight the stepper steps from: the typed number if the text reads as one, else the
    /// last stepped or remembered weight, pinned inside the range.
    private var currentWeight: Double {
        SetEntry.clampedWeight(SetEntry.weight(from: text) ?? weight)
    }

    private var steppedWeight: Binding<Double> {
        Binding(
            get: { currentWeight },
            set: { newValue in
                let stepped = SetEntry.clampedWeight(newValue)
                weight = stepped
                text = SetEntry.weightText(stepped)
            }
        )
    }
}
