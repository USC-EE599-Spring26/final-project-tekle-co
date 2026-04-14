//
//  MyCustomCardView.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/12/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  MyCustomCardView.swift
//  OCKSample
//
//  Created by Corey Baker on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import CareKitEssentials
import CareKit
import CareKitStore
import CareKitUI
import os.log
import SwiftUI

struct MyCustomCardView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    @Environment(\.isCardEnabled) private var isCardEnabled
    let event: OCKAnyEvent

    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                HStack {
                    Label(badgeTitle, systemImage: badgeIconName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.bottom, 8)
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )
                event.instructionsText
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)
                    .foregroundStyle(.secondary)
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Button(action: {
                            toggleEventCompletion()
                        }) {
                            RectangularCompletionView(isComplete: isComplete) {
                                Spacer()
                                Text(buttonText)
                                    .foregroundColor(foregroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                Spacer()
                            }
                        }
                        .buttonStyle(NoHighlightStyle())
                    }
                }
            }
            .padding(isCardEnabled ? [.all] : [])
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
            )
        }
        .careKitStyle(style)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var isComplete: Bool {
        event.isComplete
    }

    private var isRangeOfMotionTask: Bool {
        event.task.id == TaskID.rangeOfMotion
    }

    private var buttonText: LocalizedStringKey {
        if isComplete { return "COMPLETED" }
        return isRangeOfMotionTask ? "START_RANGE_OF_MOTION" : "BEGIN_ACTIVITY"
    }

    private var foregroundColor: Color {
        isComplete ? .accentColor : .white
    }

    private var badgeTitle: LocalizedStringKey {
        isRangeOfMotionTask ? "RANGE_OF_MOTION_BADGE" : "WELLNESS_ACTIVITY_BADGE"
    }

    private var badgeIconName: String {
        isRangeOfMotionTask ? "figure.strengthtraining.functional" : "brain.head.profile"
    }

    private func toggleEventCompletion() {
        Task {
            do {
                guard event.isComplete == false else {
                    let updatedOutcome = try await saveOutcomeValues([], event: event)
                    Logger.myCustomCardView.info(
                        "Updated event by removing outcome values: \(updatedOutcome.values)"
                    )
                    return
                }
                let newOutcomeValue = OCKOutcomeValue(true)
                let updatedOutcome = try await saveOutcomeValues([newOutcomeValue], event: event)
                Logger.myCustomCardView.info(
                    "Updated event by setting outcome values: \(updatedOutcome.values)"
                )
            } catch {
                Logger.myCustomCardView.info("Error saving value: \(error)")
            }
        }
    }
}

#if !os(watchOS)
extension MyCustomCardView: EventViewable {
    init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}
#endif

struct MyCustomCardView_Previews: PreviewProvider {
    static var store = Utility.createPreviewStore()
    static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.doxylamine]
        return query
    }
    static var previews: some View {
        VStack {
            @CareStoreFetchRequest(query: query) var events
            if let event = events.latest.first {
                MyCustomCardView(event: event.result)
            }
        }
        .environment(\.careStore, store)
        .padding()
    }
}
