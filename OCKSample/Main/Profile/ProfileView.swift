//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitEssentials
import HealthKit
import SwiftUI
import os.log

struct ProfileView: View {

    @CareStoreFetchRequest(query: query()) private var patients
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var showingAddTask = false
    @State private var showingManageTasks = false
    @State private var showingAddHealthKitTask = false

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    TextField("GIVEN_NAME", text: $viewModel.firstName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    TextField("FAMILY_NAME", text: $viewModel.lastName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    DatePicker(
                        "BIRTHDAY",
                        selection: $viewModel.birthday,
                        displayedComponents: [.date]
                    )
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                }

                Button(action: {
                    Task {
                        do {
                            try await viewModel.saveProfile()
                        } catch {
                            Logger.profile.error("Error saving profile: \(error)")
                        }
                    }
                }) {
                    Text("SAVE_PROFILE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                }
                .background(Color(.green))
                .cornerRadius(15)

                Button(action: {
                    Task {
                        await loginViewModel.logout()
                    }
                }) {
                    Text("LOG_OUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                }
                .background(Color(.red))
                .cornerRadius(15)
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingManageTasks = true
                        } label: {
                            Image(systemName: "trash")
                        }

                        Menu {
                            Button("Add Task") {
                                showingAddTask = true
                            }
                            Button("Add HealthKit Task") {
                                showingAddHealthKitTask = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingManageTasks) {
                ManageTasksView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddHealthKitTask) {
                AddHealthKitTaskView(viewModel: viewModel)
            }
        }
    }

    static func query() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
