//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import CareKitStore
import CareKit
import os.log
import SwiftUI

struct ProfileView: View {
    @CareStoreFetchRequest(query: ProfileViewModel.queryPatient()) private var patients
    @CareStoreFetchRequest(query: ProfileViewModel.queryContacts()) private var contacts
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var showingAddTask = false
    @State private var showingManageTasks = false
    @State private var showingAddHealthKitTask = false

    var body: some View {
        NavigationView {
            VStack {
                ProfileImageView(viewModel: viewModel)
                Form {
                    Section(header: Text("About")) {
                        TextField("First Name",
                                  text: $viewModel.firstName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                        TextField("Last Name",
                                  text: $viewModel.lastName)
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                        DatePicker("Birthday",
                                   selection: $viewModel.birthday,
                                   displayedComponents: [DatePickerComponents.date])
                        .padding()
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                        TextField("Allergies", text: $viewModel.allergies)
                    }

                    Section(header: Text("Contact")) {
                        TextField("Street", text: $viewModel.street)
                        TextField("City", text: $viewModel.city)
                        TextField("State", text: $viewModel.state)
                        TextField("Postal code", text: $viewModel.zipcode)
                        TextField("Email", text: $viewModel.emailAddress)
                        TextField("Phone", text: $viewModel.phoneNumber)
                        TextField("Messaging", text: $viewModel.messagingNumber)
                        TextField("Other Contact Info", text: $viewModel.otherContactInfo)
                    }
                }

                Button(action: {
                    Task {
                        await viewModel.saveProfile()
                    }
                }, label: {
                    Text("Save Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                })
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("My Contact") {
                        viewModel.isPresentingContact = true
                    }
                    .sheet(isPresented: $viewModel.isPresentingContact) {
                        MyContactView()
                    }
                }
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
            .sheet(isPresented: $viewModel.isPresentingImagePicker) {
                ImagePicker(image: $viewModel.profileUIImage)
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                return Alert(title: Text("Update"),
                             message: Text(viewModel.alertMessage),
                             dismissButton: .default(Text("Ok"), action: {
                                viewModel.isShowingSaveAlert = false
                             }))
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
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
        .onReceive(contacts.publisher) { publishedContact in
            viewModel.updateContact(publishedContact.result)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .accentColor(Color.accentColor)
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
