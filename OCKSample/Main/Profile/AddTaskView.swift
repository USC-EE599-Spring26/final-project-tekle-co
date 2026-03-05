import Foundation
import SwiftUI
import CareKitStore

struct AddTaskView: View {

    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var instructions = ""
    @State private var hour = 8
    @State private var errorMessage: String?
    @State private var showError = false

    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {

        NavigationView {

            Form {

                Section(header: Text("Task Info")) {

                    TextField("Title", text: $title)

                    TextField("Instructions", text: $instructions)

                    Stepper("Hour: \(hour)", value: $hour, in: 0...23)

                }

                Section {
                    Button("Save Task") {
                        Task {
                            do {
                                try await viewModel.createTask(
                                    title: title,
                                    instructions: instructions,
                                    hour: hour
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Task")
        }
    }
}
