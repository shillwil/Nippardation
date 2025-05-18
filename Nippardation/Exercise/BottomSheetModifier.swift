//
//  BottomSheetModifier.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI

enum SheetState {
    case dismissed
    case collapsed
    case expanded
}

struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var sheetState: SheetState
    let sheetContent: SheetContent
    
    // For tracking drag gesture
    @GestureState private var dragOffset: CGFloat = 0
    
    // Animation settings
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // Height configurations
    private let collapsedHeight: CGFloat = 80
    private let screenHeight = UIScreen.main.bounds.height - 150
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            // Main content
            content
                .disabled(isPresented && sheetState == .expanded)
            
            // Bottom sheet
            if isPresented {
                // Semi-transparent background overlay (only in expanded state)
//                if sheetState == .expanded {
//                    Color.black
//                        .opacity(0.3)
//                        .ignoresSafeArea()
//                        .onTapGesture {
//                            withAnimation(animation) {
//                                sheetState = .collapsed
//                            }
//                        }
//                        .transition(.opacity)
//                }
                
                // The actual sheet
                VStack(spacing: 0) {
                    // Drag handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 40, height: 5)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(Color(UIColor.systemBackground))
                    
                    // Sheet content
                    sheetContent
                        .frame(maxWidth: .infinity, maxHeight: sheetState == .expanded ? .infinity : collapsedHeight - 25)
                        .background(Color(UIColor.systemBackground))
                }
                .frame(height: sheetState == .expanded ? screenHeight : collapsedHeight)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: -5)
                .offset(y: dragOffset + (sheetState == .expanded ? 0 : 0))
                .gesture(sheetDragGesture)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(animation, value: isPresented)
        .animation(animation, value: sheetState)
    }
    
    // Drag gesture for the sheet
    private var sheetDragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                if sheetState == .expanded {
                    // Only allow dragging down from expanded state
                    state = max(0, value.translation.height)
                } else {
                    // Allow dragging up or down from collapsed state
                    state = value.translation.height
                }
            }
            .onEnded { value in
                let dragThreshold: CGFloat = 120
                
                // Determine new state based on current state and drag
                switch sheetState {
                case .expanded:
                    if value.translation.height > dragThreshold {
                        withAnimation(animation) {
                            sheetState = .collapsed
                        }
                    }
                case .collapsed:
                    if value.translation.height < -dragThreshold {
                        withAnimation(animation) {
                            sheetState = .expanded
                        }
                    } else if value.translation.height > dragThreshold {
                        withAnimation(animation) {
                            isPresented = false
                            sheetState = .dismissed
                        }
                    }
                case .dismissed:
                    break
                }
            }
    }
}

extension View {
    func bottomSheet<Content: View>(isPresented: Binding<Bool>, sheetState: Binding<SheetState>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(BottomSheetModifier(isPresented: isPresented, sheetState: sheetState, sheetContent: content()))
    }
}

// Extension for applying corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Helper shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//#Preview {
//    BottomSheetModifier(isPresented: .constant(true), sheetState: .constant(.collapsed), sheetContent: EmptyView())
//}
