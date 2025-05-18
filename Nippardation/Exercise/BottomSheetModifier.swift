//
//  BottomSheetModifier.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI

import SwiftUI

struct ExpandablePlayerModifier<ExpandedContent: View, CollapsedContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let expandedContent: ExpandedContent
    let collapsedContent: CollapsedContent
    
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    // Animation settings
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // Height configurations
    private let collapsedHeight: CGFloat = 80
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.85
    
    init(isPresented: Binding<Bool>,
         @ViewBuilder expandedContent: () -> ExpandedContent,
         @ViewBuilder collapsedContent: () -> CollapsedContent) {
        self._isPresented = isPresented
        self.expandedContent = expandedContent()
        self.collapsedContent = collapsedContent()
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            // Main content
            content
                .disabled(isPresented && isExpanded)
            
            // Player overlay
            if isPresented {
                // Semi-transparent background overlay (only in expanded state)
                if isExpanded {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(animation) {
                                isExpanded = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // The actual player view
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
                    
                    // Player content based on state
                    if isExpanded {
                        expandedContent
                            .transition(.opacity)
                    } else {
                        collapsedContent
                            .frame(height: collapsedHeight - 25)
                            .transition(.opacity)
                    }
                }
                .frame(height: isExpanded ? maxHeight : collapsedHeight)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: -5)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if isExpanded {
                                // When expanded, only allow dragging down
                                dragOffset = max(0, value.translation.height)
                            } else {
                                // When collapsed, allow dragging in both directions
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            let dragThreshold: CGFloat = 100
                            
                            if isExpanded {
                                // If expanded and dragged down enough
                                if value.translation.height > dragThreshold {
                                    withAnimation(animation) {
                                        isExpanded = false
                                        dragOffset = 0
                                    }
                                } else {
                                    // Spring back to expanded position
                                    withAnimation(animation) {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // If collapsed and dragged up enough
                                if value.translation.height < -dragThreshold {
                                    withAnimation(animation) {
                                        isExpanded = true
                                        dragOffset = 0
                                    }
                                } else if value.translation.height > dragThreshold {
                                    // If dragged down enough to dismiss
                                    withAnimation(animation) {
                                        isPresented = false
                                        dragOffset = 0
                                    }
                                } else {
                                    // Spring back to collapsed position
                                    withAnimation(animation) {
                                        dragOffset = 0
                                    }
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(animation, value: isPresented)
    }
}

extension View {
    func expandablePlayer<ExpandedContent: View, CollapsedContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent
    ) -> some View {
        self.modifier(ExpandablePlayerModifier(
            isPresented: isPresented,
            expandedContent: expandedContent,
            collapsedContent: collapsedContent)
        )
    }
}
