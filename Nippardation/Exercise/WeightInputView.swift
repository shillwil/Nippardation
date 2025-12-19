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
    
    WeightInputView(weight: $weight, weightString: $weightString)
}

#Preview {
    WeightInputView(weight: .constant(32.5), weightString: .constant("Yolo``"))
}
