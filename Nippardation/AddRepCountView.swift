//
//  AddRepCountView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/9/25.
//

import SwiftUI

struct AddRepCountView: View {
    @State private var value: Int
    
    init(repPlaceholder: Int) {
        _value = State(initialValue: repPlaceholder)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(value)")
                    .font(.title3)
                    .bold()
            }
            Stepper("Reps Completed", value: $value)
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
