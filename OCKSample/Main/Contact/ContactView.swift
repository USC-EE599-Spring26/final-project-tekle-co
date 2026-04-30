//
//  ContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import os.log
import SwiftUI

struct ContactView: View {
    @Environment(\.careStore) private var careStore
    @State private var contacts: [OCKContact] = []
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List(filteredContacts, id: \.uuid) { contact in
                NavigationLink(destination: ContactDetailView(contact: contact)) {
                    ContactRow(contact: contact)
                }
            }
            .navigationTitle("Contact")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .task {
            await refreshContacts()
        }
    }

    private var filteredContacts: [OCKContact] {
        let all = contacts
        guard !searchText.isEmpty else { return all }
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return all }
        return all.filter { contact in
            let name = "\(contact.name.givenName ?? "") \(contact.name.familyName ?? "")".lowercased()
            let title = (contact.title ?? "").lowercased()
            let role = (contact.role ?? "").lowercased()
            return name.contains(needle) || title.contains(needle) || role.contains(needle)
        }
    }

    @MainActor
    private func refreshContacts() async {
        do {
            guard let contactStore = careStore as? OCKAnyContactStore else {
                Logger.contact.error("careStore does not conform to OCKAnyContactStore")
                contacts = []
                return
            }
            let anyContacts = try await contactStore.fetchAnyContacts(query: query())
            contacts = anyContacts.compactMap { $0 as? OCKContact }
        } catch {
            Logger.contact.error("Failed to fetch contacts: \(error.localizedDescription)")
        }
    }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView()
            .environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}

private struct ContactRow: View {
    let contact: OCKContact

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.15))
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body.weight(.medium))
                if let title = contact.title, !title.isEmpty {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var displayName: String {
        let given = contact.name.givenName ?? ""
        let family = contact.name.familyName ?? ""
        let name = "\(given) \(family)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? contact.id : name
    }

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }
}

private struct ContactDetailView: View {
    let contact: OCKContact

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: displayName)
                if let title = contact.title, !title.isEmpty {
                    LabeledContent("Title", value: title)
                }
                if let role = contact.role, !role.isEmpty {
                    Text(role)
                        .foregroundColor(.secondary)
                }
            }

            Section("Reach out") {
                labeledLinks(title: "Email", values: contact.emailAddresses, urlPrefix: "mailto:")
                labeledLinks(title: "Phone", values: contact.phoneNumbers, urlPrefix: "tel:")
                labeledLinks(title: "Messaging", values: contact.messagingNumbers, urlPrefix: "sms:")
                if let other = contact.otherContactInfo?.first?.value, !other.isEmpty {
                    LabeledContent("Other", value: other)
                }
            }

            if let address = contact.address {
                Section("Address") {
                    if !address.street.isEmpty { LabeledContent("Street", value: address.street) }
                    if !address.city.isEmpty { LabeledContent("City", value: address.city) }
                    if !address.state.isEmpty { LabeledContent("State", value: address.state) }
                    if !address.postalCode.isEmpty { LabeledContent("Postal Code", value: address.postalCode) }
                    if !address.country.isEmpty { LabeledContent("Country", value: address.country) }
                }
            }
        }
        .navigationTitle("Contact")
    }

    private var displayName: String {
        let given = contact.name.givenName ?? ""
        let family = contact.name.familyName ?? ""
        let name = "\(given) \(family)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? contact.id : name
    }

    @ViewBuilder
    private func labeledLinks(
        title: String,
        values: [OCKLabeledValue]?,
        urlPrefix: String
    ) -> some View {
        let first = values?.first?.value ?? ""
        if first.isEmpty {
            EmptyView()
        } else if let url = URL(string: "\(urlPrefix)\(first)") {
            Link(destination: url) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(first)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            LabeledContent(title, value: first)
        }
    }
}

private func query() -> OCKContactQuery {
    OCKContactQuery(for: Date())
}
