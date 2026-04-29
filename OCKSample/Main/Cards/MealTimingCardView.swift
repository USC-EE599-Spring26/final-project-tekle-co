//
//  MealTimingCardView.swift
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

struct MealTimingCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    let event: OCKAnyEvent

    @State private var selectedTiming: String = ""
    @State private var selectedSize: String = ""
    @State private var isSaving = false

    private let timingOptions = [
        "1hr+ before",
        "30min before",
        "During comedown",
        "After comedown",
        "Skipped"
    ]

    private let sizeOptions = [
        "Light",
        "Medium",
        "Heavy"
    ]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {

                // Badge
                HStack {
                    Label("MEAL", systemImage: "fork.knife")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(Color.orange)
                        .clipShape(Capsule())

                    Spacer()

                    // Meal name from schedule element text
                    if let mealName = event.scheduleEvent.element.text {
                        Text(mealName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Header
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                if isComplete {
                    completedView
                } else {
                    mealInputView
                }
            }
            .padding(isCardEnabled ? [.all] : [])
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.orange.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    // MARK: - Subviews

    private var mealInputView: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Timing selection
            VStack(alignment: .leading, spacing: 8) {
                Text("When did you eat?")
                    .font(.subheadline.weight(.semibold))

                FlowLayout(spacing: 8) {
                    ForEach(timingOptions, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTiming = option
                            }
                        } label: {
                            Text(option)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTiming == option
                                        ? Color.orange
                                        : Color.orange.opacity(0.12)
                                )
                                .foregroundColor(
                                    selectedTiming == option ? .white : .orange
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Size selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal size")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    ForEach(sizeOptions, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedSize = option
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: iconForSize(option))
                                    .font(.title3)
                                Text(option)
                                    .font(.caption2.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedSize == option
                                    ? Color.orange
                                    : Color.orange.opacity(0.12)
                            )
                            .foregroundColor(
                                selectedSize == option ? .white : .orange
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Save button
            Button {
                saveMealTiming()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Log Meal")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canSave ? Color.orange : Color.gray
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave || isSaving)
        }
    }

    private var completedView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Timing result
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(savedTiming)
                        .font(.caption.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // Size result
                VStack(spacing: 4) {
                    Image(systemName: iconForSize(savedSize))
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(savedSize)
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Logged")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var isComplete: Bool {
        event.isComplete
    }

    private var canSave: Bool {
        !selectedTiming.isEmpty && !selectedSize.isEmpty
    }

    private var savedTiming: String {
        let values = event.outcome?.values ?? []
        return values.first(where: { $0.kind == "timingRelativeToComedown" })?.stringValue ?? "—"
    }

    private var savedSize: String {
        let values = event.outcome?.values ?? []
        return values.first(where: { $0.kind == "mealSize" })?.stringValue ?? "—"
    }

    private func iconForSize(_ size: String) -> String {
        switch size {
        case "Light":
            return "leaf.fill"
        case "Medium":
            return "fork.knife"
        case "Heavy":
            return "takeoutbag.and.cup.and.straw.fill"
        default:
            return "questionmark.circle"
        }
    }

    private func saveMealTiming() {
        isSaving = true
        Task {
            do {
                let mealName = event.scheduleEvent.element.text ?? "meal"

                var timingValue = OCKOutcomeValue(selectedTiming)
                timingValue.kind = "timingRelativeToComedown"

                var sizeValue = OCKOutcomeValue(selectedSize)
                sizeValue.kind = "mealSize"

                var mealTypeValue = OCKOutcomeValue(mealName)
                mealTypeValue.kind = "mealType"

                let updatedOutcome = try await saveOutcomeValues(
                    [timingValue, sizeValue, mealTypeValue],
                    event: event
                )
                Logger.myCustomCardView.info(
                    "Saved meal timing: \(updatedOutcome.values)"
                )
            } catch {
                Logger.myCustomCardView.error(
                    "Error saving meal timing: \(error)"
                )
            }
            isSaving = false
        }
    }
}

/// Simple flow layout that wraps items to the next line.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layoutSubviews(
            proposal: proposal,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layoutSubviews(
            proposal: proposal,
            subviews: subviews
        )
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                proposal: .unspecified
            )
        }
    }

    private func layoutSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions = [CGPoint]()
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (
            size: CGSize(width: maxX, height: currentY + lineHeight),
            positions: positions
        )
    }
}

#if !os(watchOS)
extension MealTimingCardView: EventViewable {
    init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif
