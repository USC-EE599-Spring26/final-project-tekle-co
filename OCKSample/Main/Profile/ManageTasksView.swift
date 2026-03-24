//
//  ManageTasksView.swift
//  OCKSample
//
//  Created by Noah Tekle on 3/5/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKitStore

struct ManageTasksView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var tasks: [OCKAnyTask] = []
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading tasks...")
                } else if tasks.isEmpty {
                    Text("No tasks found.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(tasks, id: \.id) { task in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title ?? "Untitled")
                                        .font(.headline)
                                    if let instructions = task.instructions {
                                        Text(instructions)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if task is OCKHealthKitTask {
                                        Text("HealthKit")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await viewModel.deleteAnyTask(task)
                                            tasks.removeAll { $0.id == task.id }
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                do {
                    tasks = try await viewModel.fetchAllAnyTasks()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}
