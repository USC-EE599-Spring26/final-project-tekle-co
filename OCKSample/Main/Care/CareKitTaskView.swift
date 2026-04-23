//
//  CareKitTaskView.swift
//  OCKSample
//

#if os(iOS)
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
import ResearchKit
import ResearchKitUI
import SwiftUI
import UIKit

// MARK: - Helpers to find the right UIViewController for presenting ORK modals

private enum SurveyPresentationHost {

    static func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController ?? tab)
        }
        return root
    }

    /// Presents from the key window so ORK modals dismiss correctly.
    static func host(fallback: UIViewController) -> UIViewController {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: {
            $0.activationState == .foregroundActive
        }) ?? scenes.first
        guard let windowScene = scene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
                ?? windowScene.windows.first,
              let root = window.rootViewController,
              let top = topViewController(from: root) else {
            return fallback
        }
        return top
    }
}

// MARK: - Bridge to grab a UIViewController reference from SwiftUI

private struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            onResolve(viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Delegate that manages the ORK survey lifecycle

private final class ORKSurveyPresentationDelegate: NSObject,
    ObservableObject,
    ORKTaskViewControllerDelegate,
    @unchecked Sendable {

    var save: (([OCKOutcomeValue]) async throws -> Void)?
    private var pendingKind: Survey?

    func presentSurvey(kind: Survey, from presenter: UIViewController) {
        pendingKind = kind
        let surveyable = kind.type()
        let task = surveyable.createSurvey()
        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        taskViewController.delegate = self
        taskViewController.outputDirectory = FileManager.default.temporaryDirectory
        let host = SurveyPresentationHost.host(fallback: presenter)
        host.present(taskViewController, animated: true)
    }

    func taskViewController(
        _ taskViewController: ORKTaskViewController,
        didFinishWith reason: ORKTaskFinishReason,
        error: Error?
    ) {
        let kind = pendingKind
        pendingKind = nil
        let saveClosure = save

        DispatchQueue.main.async {
            let result = taskViewController.result
            guard reason == .completed, error == nil, let kind else {
                taskViewController.dismiss(animated: true)
                return
            }

            let values = kind.type().extractAnswers(result) ?? []

            Task {
                func finishAndNotify() async {
                    if kind == .onboard {
                        UserDefaults.standard.set(
                            true,
                            forKey: Constants.researchKitOnboardingCompletedKey
                        )
                    }
                    await MainActor.run {
                        taskViewController.dismiss(animated: true) {
                            NotificationCenter.default.post(
                                name: Notification.Name(
                                    rawValue: Constants.shouldRefreshView
                                ),
                                object: nil
                            )
                        }
                    }
                }

                if values.isEmpty {
                    Logger.careKitTask.warning(
                        "Survey finished with no outcome values; kind=\(String(describing: kind))"
                    )
                    if kind == .onboard {
                        await finishAndNotify()
                    } else {
                        await MainActor.run {
                            taskViewController.dismiss(animated: true)
                        }
                    }
                    return
                }

                guard let saveClosure else {
                    Logger.careKitTask.error(
                        "Survey save closure nil"
                    )
                    if kind == .onboard {
                        await finishAndNotify()
                    } else {
                        await MainActor.run {
                            taskViewController.dismiss(animated: true)
                        }
                    }
                    return
                }

                do {
                    try await saveClosure(values)
                    await finishAndNotify()
                } catch {
                    await MainActor.run {
                        Logger.careKitTask.error(
                            "Failed to save survey outcome: \(error.localizedDescription, privacy: .public)"
                        )
                        if kind == .onboard {
                            UserDefaults.standard.set(
                                true,
                                forKey: Constants.researchKitOnboardingCompletedKey
                            )
                            taskViewController.dismiss(animated: true) {
                                NotificationCenter.default.post(
                                    name: Notification.Name(
                                        rawValue: Constants.shouldRefreshView
                                    ),
                                    object: nil
                                )
                            }
                        } else {
                            taskViewController.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - The SwiftUI card view

struct CareKitTaskView: CareKitEssentialView {
    @Environment(\.careStore) var store
    @Environment(\.customStyler) var style
    let event: OCKAnyEvent

    @State private var presenter: UIViewController?
    @StateObject private var orkDelegate = ORKSurveyPresentationDelegate()

    private var ockTask: OCKTask? {
        event.task as? OCKTask
    }

    private var surveyKind: Survey? {
        ockTask?.uiKitSurvey
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                InformationHeaderView(
                    title: Text(event.title),
                    information: event.detailText,
                    event: event
                )

                event.instructionsText
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)

                Button {
                    guard let presenter, let kind = surveyKind else { return }
                    orkDelegate.presentSurvey(kind: kind, from: presenter)
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .disabled(surveyKind == nil || event.isComplete)
            }
            .padding()
        }
        .careKitStyle(style)
        .background(
            ViewControllerResolver { presenter = $0 }
        )
        .onAppear {
            orkDelegate.save = { values in
                guard !values.isEmpty else { return }
                _ = try await saveOutcomeValues(values, event: event)
            }
        }
    }

    private var buttonTitle: String {
        event.isComplete
            ? String(localized: "COMPLETED")
            : String(localized: "START_SURVEY")
    }
}

extension CareKitTaskView: EventViewable {
    init?(
        event: OCKAnyEvent,
        store: any OCKAnyStoreProtocol
    ) {
        self.init(event: event)
    }
}

#endif
