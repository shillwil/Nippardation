//
//  BottomSheetModifier.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//
//  Void sheet chrome shared by the set-entry sheets (Add set / Edit set / Weight):
//  the grabber + eyebrow-title header, the panel-2 stepper wells that hold
//  `VoidFont.stepper` numbers, the 44pt close control and form-sized segmented control,
//  and the expandable player overlay.
//

import SwiftUI

// MARK: - Sheet header

/// Grabber (36×5, text-3) over an eyebrow title with an optional trailing control.
/// The row stands 44pt so a `LoggerCloseButton` hit area fits without clipping.
struct LoggerSheetHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            VoidGrabber()
                .padding(.top, 10)
                .padding(.bottom, 14)
            HStack(alignment: .center) {
                Text(title).voidEyebrow()
                    .lineLimit(1)
                Spacer(minLength: VoidSpace.s3)
                trailing()
            }
            .frame(minHeight: VoidSize.hitMin)
            .padding(.horizontal, VoidSpace.insetText)
            .padding(.bottom, VoidSpace.s2)
        }
    }
}

extension LoggerSheetHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title, trailing: { EmptyView() })
    }
}

// MARK: - Close control

/// The sheet's only header control: the 32pt panel glyph of `VoidControlButton` (radius 8,
/// panel + hairline-2) centred in a 44pt hit area. `VoidPanelButtonStyle` limits its tappable
/// shape to the 32pt glyph, so the larger frame has to live inside the button label.
struct LoggerCloseButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    init(accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: VoidIcon.close.systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(VoidColor.text)
                .frame(width: VoidSize.control, height: VoidSize.control)
                .background(VoidColor.panel)
                .clipShape(RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                        .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                )
                .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        // Keep the glyph on the 20pt text line: the extra 6pt of hit area hangs into the inset.
        .padding(.trailing, (VoidSize.control - VoidSize.hitMin) / 2)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Segmented control

/// Form-sized segmented control: the chrome of `VoidSegmentedControl` (panel + hairline-2,
/// radius 8, 2pt padding, selected item panel-2 with radius 6) with items that fill the width
/// and stand 40pt tall, so the whole control meets the 44pt hit minimum. The 28pt
/// `VoidSegmentedControl` stays reserved for eyebrow rows.
struct LoggerSegmentedControl<Item: Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    @Binding var selection: Item

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                let on = item == selection
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .voidChipLabel(on ? VoidColor.text : VoidColor.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, VoidSpace.s3)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: VoidSize.hitMin - 4)
                        .background(on ? VoidColor.panel2 : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.mark, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(VoidPlainButtonStyle())
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .padding(2)
        .voidPanel(radius: VoidRadius.control, line: VoidColor.hairline2)
    }
}

// MARK: - Stepper well

/// Panel-2 well (radius 12): minus control · number in `VoidFont.stepper` · plus control.
struct LoggerStepperWell: View {
    let value: String
    var unit: String? = nil
    var decrementLabel: String = "Decrease"
    var incrementLabel: String = "Increase"
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            wellControl(systemName: LoggerGlyph.minus, label: decrementLabel, action: onDecrement)
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(VoidFont.stepper)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let unit {
                    Text(unit).voidEyebrowSm()
                }
            }
            Spacer(minLength: 0)
            wellControl(systemName: VoidIcon.plus.systemName, label: incrementLabel, action: onIncrement)
        }
        .padding(.horizontal, 6)
        .frame(height: LoggerMetrics.wellHeight)
        .frame(maxWidth: .infinity)
        .background(VoidColor.panel2)
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
    }

    private func wellControl(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(VoidColor.text)
                .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Value well

/// Panel-2 well that opens an editor when tapped: number in `VoidFont.stepper`, unit, chevron.
struct LoggerValueWell: View {
    let value: String
    var unit: String? = nil
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Spacer(minLength: VoidSize.hitMin)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(VoidFont.stepper)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let unit {
                        Text(unit).voidEyebrowSm()
                    }
                }
                Spacer(minLength: 0)
                VoidChevron(color: VoidColor.text2)
                    .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
            }
            .padding(.horizontal, 6)
            .frame(height: LoggerMetrics.wellHeight)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(VoidPanelButtonStyle(radius: VoidRadius.tile, line: .clear, fill: VoidColor.panel2, pressedFill: VoidColor.panel))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(unit.map { "\(value) \($0)" } ?? value)
    }
}

// MARK: - Field label

/// Eyebrow-sm label above a well, inset to the 20pt text line inside a 16pt card inset.
struct LoggerFieldLabel: View {
    let title: String
    var body: some View {
        Text(title).voidEyebrowSm()
            .padding(.leading, VoidSpace.insetText - VoidSpace.insetCard)
    }
}

// MARK: - Shared metrics / glyphs

enum LoggerMetrics {
    /// Stepper and value wells.
    static let wellHeight: CGFloat = 56
}

/// SF Symbols the logger needs that `VoidIcon` does not carry.
enum LoggerGlyph {
    static let minus = "minus"
}

// MARK: - Expandable player overlay

struct ExpandablePlayerModifier<ExpandedContent: View, CollapsedContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let expandedContent: ExpandedContent
    let collapsedContent: CollapsedContent

    @State private var isExpanded: Bool = true
    @State private var dragOffset: CGFloat = 0

    // Motion: nothing bounces.
    private let animation = Animation.easeOut(duration: 0.2)

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
                // Scrim (only in expanded state)
                if isExpanded {
                    VoidColor.scrim
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
                    // Grabber
                    VoidGrabber()
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity)
                        .background(VoidColor.panel)

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
                .background(VoidColor.panel)
                .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tabBar, style: .continuous))
                .overlay(alignment: .top) {
                    Rectangle().fill(VoidColor.hairline2).frame(height: 1)
                }
                .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: -12)
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

#Preview("Logger wells") {
    ZStack {
        VoidColor.panel.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 16) {
            LoggerSheetHeader(title: "Add set") {
                LoggerCloseButton(accessibilityLabel: "Close") { }
            }
            VStack(alignment: .leading, spacing: 6) {
                LoggerFieldLabel(title: "Reps")
                LoggerStepperWell(value: "08", unit: "reps", onDecrement: {}, onIncrement: {})
            }
            VStack(alignment: .leading, spacing: 6) {
                LoggerFieldLabel(title: "Set type")
                LoggerSegmentedControl(items: ["Warm-up", "Working"], label: { $0 }, selection: .constant("Working"))
            }
            VStack(alignment: .leading, spacing: 6) {
                LoggerFieldLabel(title: "Weight · lbs")
                LoggerValueWell(value: "135.0", unit: "lbs", accessibilityLabel: "Weight") { }
            }
        }
        .padding(.horizontal, VoidSpace.insetCard)
    }
}
