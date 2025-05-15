//
//  WeightInputView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI

struct WeightInputView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var weight: Double
    @Binding var weightString: String
    
    // Common weight presets based on standard plate increments
    let weightPresets: [[Double]] = [
        [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0], // Light weights
        [45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0], // Moderate weights
        [90.0, 95.0, 100.0, 115.0, 135.0, 155.0, 175.0, 185.0], // Medium weights
        [195.0, 205.0, 225.0, 245.0, 275.0, 295.0, 315.0, 335.0], // Heavy weights
        [365.0, 385.0, 405.0, 455.0, 495.0, 500.0, 545.0, 585.0]  // Very heavy weights
    ]
    
    // Step increments
    let increments: [Double] = [2.5, 5.0, 10.0, 25.0, 45.0]
    @State private var selectedIncrement: Double = 5.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current weight display
                    VStack(spacing: 4) {
                        Text("WEIGHT")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("\(weight, specifier: "%.1f") lbs")
                            .font(.system(size: 48, weight: .bold))
                            .padding()
                    }
                    
                    // Weight increment selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADJUST BY")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(increments, id: \.self) { increment in
                                Button {
                                    selectedIncrement = increment
                                } label: {
                                    Text(increment == 2.5 ? "2½" : "\(Int(increment))")
                                        .font(.headline)
                                        .frame(minWidth: 40)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(selectedIncrement == increment ? Color.appTheme : Color(.secondarySystemBackground))
                                        .foregroundColor(selectedIncrement == increment ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Increment/decrement buttons
                    HStack(spacing: 20) {
                        Button {
                            let newWeight = max(0, weight - selectedIncrement)
                            weight = newWeight
                            weightString = String(format: "%.1f", newWeight)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.appTheme)
                        }
                        
                        Button {
                            let newWeight = weight + selectedIncrement
                            weight = newWeight
                            weightString = String(format: "%.1f", newWeight)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.appTheme)
                        }
                    }
                    .padding(.vertical)
                    
                    // Custom weight input
                    HStack {
                        Text("Custom Weight:")
                            .font(.headline)
                        
                        TextField("Enter weight", text: $weightString)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        
                        Button("Set") {
                            if let newWeight = Double(weightString) {
                                weight = newWeight
                            }
                        }
                        .tint(Color.appTheme)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    
                    // Weight preset suggestions
                    Text("COMMON WEIGHTS")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Scrollable presets by category
                    //                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(weightPresets, id: \.self) { presetGroup in
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                                ForEach(presetGroup, id: \.self) { preset in
                                    Button {
                                        weight = preset
                                        weightString = String(format: "%.1f", preset)
                                    } label: {
                                        Text("\(Int(preset))")
                                            .font(.headline)
                                            .frame(minWidth: 60)
                                            .padding(.vertical, 12)
                                            .background(abs(weight - preset) < 0.1 ? Color.appTheme : Color(.secondarySystemBackground))
                                            .foregroundColor(abs(weight - preset) < 0.1 ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            if presetGroup != weightPresets.last {
                                Divider()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        // Ensure weight is valid
                        if let newWeight = Double(weightString) {
                            weight = newWeight
                        }
                        dismiss()
                    } label: {
                        Text("Confirm Weight")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appTheme)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("Enter Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            if let newWeight = Double(weightString) {
                                weight = newWeight
                            }
                            dismiss()
                        }
                        .tint(Color.appTheme)
                    }
                }
                .onAppear {
                    // Format weight string on appear
                    weightString = String(format: "%.1f", weight)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var weight: Double = 45.0
    @Previewable @State var weightString: String = "45.0"
    
    return WeightInputView(weight: $weight, weightString: $weightString)
}

#Preview {
    WeightInputView(weight: .constant(32.5), weightString: .constant("Yolo``"))
}
