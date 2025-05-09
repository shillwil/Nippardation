//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var value: Int
    @Environment(\.dismiss) var dismiss
    
    init(repPlaceholder: Int) {
        _value = State(initialValue: repPlaceholder)
    }
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color(uiColor: .systemGray))
                }
            }
            Text("\(value)")
                .font(.system(size: 96, weight: .bold))
            
            Stepper("Reps Completed", value: $value)
            
            Spacer()
            
            Button {
                // Add Save Rep Action Here
            } label: {
                Text("Save")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .padding(.vertical)

            }
        }
        .padding()
    }
}

#Preview {
    AddRepCountView(repPlaceholder: 8)
}
