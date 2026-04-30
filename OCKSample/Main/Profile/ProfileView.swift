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
import PhotosUI

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
                ScrollView {
                    VStack(spacing: 16) {
                        ProfileHeader(viewModel: viewModel)

                        Form {
                            Section("About") {
                                TextField("First Name", text: $viewModel.firstName)
                                TextField("Last Name", text: $viewModel.lastName)
                                DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: [.date])
                                TextField("Allergies", text: $viewModel.allergies)
                            }

                            Section("Contact") {
                                TextField("Street", text: $viewModel.street)
                                TextField("City", text: $viewModel.city)
                                TextField("State", text: $viewModel.state)
                                TextField("Postal code", text: $viewModel.zipcode)
                                TextField("Country", text: $viewModel.country)
                                TextField("Email", text: $viewModel.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                TextField("Phone", text: $viewModel.phoneNumber)
                                    .keyboardType(.phonePad)
                                TextField("Messaging", text: $viewModel.messagingNumber)
                                    .keyboardType(.phonePad)
                                TextField("Other Contact Info", text: $viewModel.otherContactInfo)
                            }
                        }
                        .frame(minHeight: 420)

                        Button {
                            Task { await viewModel.saveProfile() }
                        } label: {
                            Text("Save Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 320)
                        }
                        .background(Color(.systemGreen))
                        .cornerRadius(14)

                        Button {
                            Task { await loginViewModel.logout() }
                        } label: {
                            Text("LOG_OUT")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 320)
                        }
                        .background(Color(.systemRed))
                        .cornerRadius(14)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("My Contact") {
                        viewModel.isPresentingMyContact = true
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
            .sheet(isPresented: $showingManageTasks) {
                ManageTasksView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddHealthKitTask) {
                AddHealthKitTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isPresentingMyContact) {
                MyContactView(viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.isShowingSaveAlert) {
                Alert(
                    title: Text("Update"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("Ok")) {
                        viewModel.isShowingSaveAlert = false
                    }
                )
            }
            .onReceive(patients.publisher) { publishedPatient in
                viewModel.updatePatient(publishedPatient.result)
            }
            .onReceive(contacts.publisher) { publishedContact in
                viewModel.updateContact(publishedContact.result)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(loginViewModel: .init())
            .environment(\.careStore, Utility.createPreviewStore())
    }
}

private struct ProfileHeader: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                profileImage
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.secondary.opacity(0.35), lineWidth: 1))

                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .padding(4)
            }

            Text("\(viewModel.firstName) \(viewModel.lastName)".trimmingCharacters(in: .whitespaces))
                .font(.headline)
        }
        .onChange(of: viewModel.selectedPhotoItem) { _ in
            Task { await viewModel.loadSelectedPhoto() }
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        #if canImport(UIKit)
        if let uiImage = viewModel.profileUIImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
        }
        #else
        if let data = viewModel.profileUIImageData, let image = Image(data: data) {
            image
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
        }
        #endif
    }
}

private struct MyContactView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationView {
            Form {
                Section("Address") {
                    LabeledContent("Street", value: viewModel.street)
                    LabeledContent("City", value: viewModel.city)
                    LabeledContent("State", value: viewModel.state)
                    LabeledContent("Postal Code", value: viewModel.zipcode)
                    LabeledContent("Country", value: viewModel.country)
                }
                Section("Reach me") {
                    contactLinkRow(label: "Email", value: viewModel.emailAddress, urlPrefix: "mailto:")
                    contactLinkRow(label: "Phone", value: viewModel.phoneNumber, urlPrefix: "tel:")
                    contactLinkRow(label: "Messaging", value: viewModel.messagingNumber, urlPrefix: "sms:")
                    LabeledContent("Other", value: viewModel.otherContactInfo)
                }
            }
            .navigationTitle("My Contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func contactLinkRow(label: String, value: String, urlPrefix: String) -> some View {
        if value.isEmpty {
            LabeledContent(label, value: "")
        } else if let url = URL(string: "\(urlPrefix)\(value)") {
            Link(destination: url) {
                HStack {
                    Text(label)
                    Spacer()
                    Text(value)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            LabeledContent(label, value: value)
        }
    }
}

// Helper for non-UIKit builds (keeps compiler happy if needed).
private extension Image {
    init?(data: Data) {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            self = Image(uiImage: uiImage)
        } else {
            return nil
        }
        #else
        return nil
        #endif
    }
}
