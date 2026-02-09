//
//  TemplateSelectorSheet.swift
//  Nippardation
//
//  Simplified template picker for the program wizard
//

import SwiftUI

struct TemplateSelectorSheet: View {
    let templates: [Template]
    let isLoading: Bool
    let onSelect: (Template) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading templates...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates", systemImage: "doc.text")
                    } description: {
                        Text("Create a template first to use in your program")
                    }
                } else {
                    List(templates) { template in
                        Button {
                            onSelect(template)
                            dismiss()
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                IconCircle(
                                    icon: "doc.text.fill",
                                    color: .appTheme,
                                    size: 36
                                )

                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text(template.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text("\(template.exerciseCount) exercises · \(template.totalWorkingSets) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TemplateSelectorSheet(
        templates: MockTemplateRepository.sampleTemplates,
        isLoading: false,
        onSelect: { _ in }
    )
}
