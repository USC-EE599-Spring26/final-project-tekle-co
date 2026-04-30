//
//  ComedownSeverityCardView.swift
//  OCKSample
//
//  Created for ADHD Comedown Tracker.
//

import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct ComedownSeverityCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    @State private var selectedSeverity: Int = 5
    @State private var isSaving = false

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {

                // Badge
                HStack {
                    Label("COMEDOWN", systemImage: "brain.head.profile.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(severityColor)
                        .clipShape(Capsule())
                    Spacer()
                }

                // Header
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                event.instructionsText
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                if isComplete {
                    // Show saved result
                    completedView
                } else {
                    // Severity picker
                    severityInputView
                }
            }
            .padding(isCardEnabled ? [.all] : [])
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(severityColor.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(severityColor.opacity(0.3), lineWidth: 1)
            )
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    // MARK: - Subviews

    private var severityInputView: some View {
        VStack(spacing: 16) {
            // Number display
            Text("\(selectedSeverity)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(colorForSeverity(selectedSeverity))

            Text(labelForSeverity(selectedSeverity))
                .font(.subheadline.weight(.medium))
                .foregroundColor(colorForSeverity(selectedSeverity))

            // Severity buttons grid
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSeverity = value
                        }
                    } label: {
                        Text("\(value)")
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedSeverity == value
                                    ? colorForSeverity(value)
                                    : colorForSeverity(value).opacity(0.15)
                            )
                            .foregroundColor(
                                selectedSeverity == value ? .white : colorForSeverity(value)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Labels under the scale
            HStack {
                Text("Minimal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Severe")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Save button
            Button {
                saveSeverity()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Log Severity")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colorForSeverity(selectedSeverity))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }

    private var completedView: some View {
        VStack(spacing: 8) {
            let savedValue = savedSeverity
            Text("\(savedValue)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(colorForSeverity(savedValue))

            Text(labelForSeverity(savedValue))
                .font(.subheadline.weight(.medium))
                .foregroundColor(colorForSeverity(savedValue))

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Logged")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.green)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var isComplete: Bool {
        event.isComplete
    }

    private var savedSeverity: Int {
        let values = event.outcome?.values ?? []
        let match = values.first(where: { $0.kind == "severity" })
        return match?.integerValue ?? 0
    }

    private var severityColor: Color {
        colorForSeverity(isComplete ? savedSeverity : selectedSeverity)
    }

    private func colorForSeverity(_ value: Int) -> Color {
        switch value {
        case 1...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }

    private func labelForSeverity(_ value: Int) -> String {
        switch value {
        case 1...2:
            return "Feeling good"
        case 3...4:
            return "Mild fog"
        case 5...6:
            return "Moderate crash"
        case 7...8:
            return "Rough comedown"
        case 9...10:
            return "Severe crash"
        default:
            return "Rate your comedown"
        }
    }

    private func saveSeverity() {
        isSaving = true
        Task {
            do {
                var severityValue = OCKOutcomeValue(selectedSeverity)
                severityValue.kind = "severity"
                let updatedOutcome = try await saveOutcomeValues(
                    [severityValue],
                    event: event
                )
                Logger.myCustomCardView.info(
                    "Saved comedown severity: \(updatedOutcome.values)"
                )
            } catch {
                Logger.myCustomCardView.error(
                    "Error saving comedown severity: \(error)"
                )
            }
            isSaving = false
        }
    }
}

#if !os(watchOS)
extension ComedownSeverityCardView: EventViewable {
    init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif
