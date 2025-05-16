//
//  EditSetView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI

// Edit Set View for modifying existing sets
struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reps: Int
    @Binding var weight: Double
    var onSave: (Int, Double) -> Void
    
    @State private var weightString: String = ""
    @State private var showingWeightPicker = false
    
    init(reps: Binding<Int>, weight: Binding<Double>, onSave: @escaping (Int, Double) -> Void) {
        self._reps = reps
        self._weight = weight
        self.onSave = onSave
        self._weightString = State(initialValue: String(format: "%.1f", weight.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Set")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Reps section
                VStack(alignment: .leading, spacing: 8) {
                    Text("REPS")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button {
                            if reps > 1 {
                                reps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("\(reps)")
                            .font(.system(size: 48, weight: .bold))
                        
                        Spacer()
                        
                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Weight section
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEIGHT (LBS)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingWeightPicker = true
                    } label: {
                        HStack {
                            Text("\(weight, specifier: "%.1f")")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button {
                    onSave(reps, weight)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave(reps, weight)
                    dismiss()
                }
            )
            .sheet(isPresented: $showingWeightPicker) {
                WeightInputView(weight: $weight, weightString: $weightString)
                    .presentationDetents([.fraction(0.667)])
            }
        }
    }
}

#Preview {
    EditSetView(reps: .constant(8), weight: .constant(42.5)) { _, _ in
        
    }
}
