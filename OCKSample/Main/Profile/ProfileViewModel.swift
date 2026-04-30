import CareKit
import CareKitStore
import CareKitEssentials
import ParseSwift
import SwiftUI
import os.log
import HealthKit
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: Editable fields
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthday = Date()
    @Published var allergies = ""

    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipcode = ""
    @Published var country = ""
    @Published var emailAddress = ""
    @Published var phoneNumber = ""
    @Published var messagingNumber = ""
    @Published var otherContactInfo = ""

    // MARK: UI state
    @Published var isShowingSaveAlert = false
    @Published var alertMessage = "All changes saved successfully!"
    @Published var isPresentingMyContact = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    #if canImport(UIKit)
    @Published var profileUIImage: UIImage? = UIImage(systemName: "person.fill")
    #else
    @Published var profileUIImageData: Data?
    #endif

    private var isSettingProfilePictureForFirstTime = true
    private var contact: OCKContact?

    var patient: OCKPatient? {
        willSet {
            if let currentFirstName = newValue?.name.givenName {
                firstName = currentFirstName
            } else {
                firstName = ""
            }
            if let currentLastName = newValue?.name.familyName {
                lastName = currentLastName
            } else {
                lastName = ""
            }
            if let currentBirthday = newValue?.birthday {
                birthday = currentBirthday
            } else {
                birthday = Date()
            }
            if let currentAllergies = newValue?.allergies?.first {
                allergies = currentAllergies
            } else {
                allergies = ""
            }
        }
    }

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              patient.uuid != self.patient?.uuid else {
            return
        }
        self.patient = patient
        Task {
            await fetchProfilePictureIfNeeded()
        }
    }

    func updateContact(_ contact: OCKAnyContact) {
        guard let currentPatient = self.patient,
              let contact = contact as? OCKContact,
              contact.id == currentPatient.id,
              contact.uuid != self.contact?.uuid else {
            return
        }
        self.contact = contact
        street = contact.address?.street ?? ""
        city = contact.address?.city ?? ""
        state = contact.address?.state ?? ""
        zipcode = contact.address?.postalCode ?? ""
        country = contact.address?.country ?? ""
        emailAddress = contact.emailAddresses?.first?.value ?? ""
        phoneNumber = contact.phoneNumbers?.first?.value ?? ""
        messagingNumber = contact.messagingNumbers?.first?.value ?? ""
        otherContactInfo = contact.otherContactInfo?.first?.value ?? ""
    }

    func saveProfile() async {
        alertMessage = "All changes saved successfully!"
        do {
            try await savePatient()
            try await saveContact()
        } catch {
            alertMessage = "Could not save profile: \(error.localizedDescription)"
        }
        isShowingSaveAlert = true
    }

    // MARK: - Persist patient
    private func savePatient() async throws {
        guard var patientToUpdate = patient else {
            throw AppError.errorString("The profile is missing the Patient")
        }

        var hasUpdates = false
        if patient?.name.givenName != firstName {
            patientToUpdate.name.givenName = firstName
            hasUpdates = true
        }
        if patient?.name.familyName != lastName {
            patientToUpdate.name.familyName = lastName
            hasUpdates = true
        }
        if patient?.birthday != birthday {
            patientToUpdate.birthday = birthday
            hasUpdates = true
        }
        if patient?.allergies?.first != allergies {
            patientToUpdate.allergies = allergies.isEmpty ? nil : [allergies]
            hasUpdates = true
        }

        guard hasUpdates else { return }

        guard let anyPatient = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate),
              let updatedPatient = anyPatient as? OCKPatient else {
            throw AppError.errorString("Could not update Patient")
        }
        self.patient = updatedPatient
        Logger.profile.info("Updated patient")
    }

    // MARK: - Persist contact
    private func saveContact() async throws {
        guard let patient = patient else {
            throw AppError.errorString("Patient not available")
        }

        if var contactToUpdate = contact {
            var hasUpdates = false
            if contactToUpdate.name != patient.name {
                contactToUpdate.name = patient.name
                hasUpdates = true
            }
            let proposedAddress = OCKPostalAddress(
                street: street,
                city: city,
                state: state,
                postalCode: zipcode,
                country: country
            )
            if contactToUpdate.address != proposedAddress {
                contactToUpdate.address = proposedAddress
                hasUpdates = true
            }
            if (contactToUpdate.emailAddresses?.first?.value ?? "") != emailAddress {
                contactToUpdate.emailAddresses = emailAddress.isEmpty ? nil : [OCKLabeledValue(label: "email", value: emailAddress)]
                hasUpdates = true
            }
            if (contactToUpdate.phoneNumbers?.first?.value ?? "") != phoneNumber {
                contactToUpdate.phoneNumbers = phoneNumber.isEmpty ? nil : [OCKLabeledValue(label: "phone", value: phoneNumber)]
                hasUpdates = true
            }
            if (contactToUpdate.messagingNumbers?.first?.value ?? "") != messagingNumber {
                contactToUpdate.messagingNumbers = messagingNumber.isEmpty ? nil : [OCKLabeledValue(label: "messaging", value: messagingNumber)]
                hasUpdates = true
            }
            if (contactToUpdate.otherContactInfo?.first?.value ?? "") != otherContactInfo {
                contactToUpdate.otherContactInfo = otherContactInfo.isEmpty ? nil : [OCKLabeledValue(label: "other", value: otherContactInfo)]
                hasUpdates = true
            }

            guard hasUpdates else { return }
            _ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
            Logger.profile.info("Updated contact")
        } else {
            // Create "my contact" record keyed to patient.id
            let newContact = OCKContact(
                id: patient.id,
                name: patient.name,
                carePlanUUID: nil
            )
            let saved = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
            if let savedContact = saved as? OCKContact {
                contact = savedContact
                try await saveContact() // apply field values after create
            }
        }
    }

    // MARK: - Profile picture (Parse)
    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                #if canImport(UIKit)
                self.profileUIImage = UIImage(data: data) ?? self.profileUIImage
                #else
                self.profileUIImageData = data
                #endif
                self.isSettingProfilePictureForFirstTime = false
                await saveProfilePictureToParseIfNeeded(data: data)
            }
        } catch {
            Logger.profile.error("Failed to load selected photo: \(error.localizedDescription)")
        }
    }

    private func fetchProfilePictureIfNeeded() async {
        guard isSettingProfilePictureForFirstTime else { return }
        defer { isSettingProfilePictureForFirstTime = false }
        guard let currentUser = (try? await User.current().fetch()) else {
            Logger.profile.error("User not logged in")
            return
        }
        guard let pictureFile = currentUser.profilePicture else { return }
        do {
            let fetched = try await pictureFile.fetch()
            guard let path = fetched.localURL?.relativePath else { return }
            #if canImport(UIKit)
            self.profileUIImage = UIImage(contentsOfFile: path)
            #else
            self.profileUIImageData = try? Data(contentsOf: URL(fileURLWithPath: path))
            #endif
        } catch {
            Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription)")
        }
    }

    private func saveProfilePictureToParseIfNeeded(data: Data) async {
        guard !isSettingProfilePictureForFirstTime else { return }
        guard var currentUser = (try? await User.current()) else { return }
        let file = ParseFile(name: "profile.jpg", data: data)
        currentUser = currentUser.set(\.profilePicture, to: file)
        do {
            _ = try await currentUser.save()
            Logger.profile.info("Saved profile picture")
        } catch {
            Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
        }
    }

    func createTask(title: String, instructions: String, hour: Int) async throws {

        guard let store = AppDelegateKey.defaultValue?.store else {
            throw AppError.errorString("Store not available")
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())

        let schedule = OCKSchedule.dailyAtTime(
            hour: hour,
            minutes: 0,
            start: startOfDay,
            end: nil,
            text: nil  // Change this from instructions to nil
        )

        var task = OCKTask(
            id: UUID().uuidString,
            title: title,
            carePlanUUID: nil,  // No care plan needed
            schedule: schedule
        )

        task.instructions = instructions

        _ = try await store.addAnyTask(task)

        print("Task saved successfully: \(title)")

        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }

    func createHealthKitTask(
        title: String,
        instructions: String,
        hour: Int,
        quantityIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        assetName: String? = nil
    ) async throws {

        guard let store = AppDelegateKey.defaultValue?.healthKitStore else {
            throw AppError.errorString("HealthKit store not available")
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())

        let schedule = OCKSchedule.dailyAtTime(
            hour: hour,
            minutes: 0,
            start: startOfDay,
            end: nil,
            text: nil
        )

        var task = OCKHealthKitTask(
            id: UUID().uuidString,
            title: title,
            carePlanUUID: nil,
            schedule: schedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: quantityIdentifier,
                quantityType: .cumulative,
                unit: unit
            )
        )

        task.instructions = instructions
        task.asset = assetName

        print("Saving task with asset: \(task.asset ?? "nil")")

        _ = try await store.addAnyTask(task)

        print("HealthKit Task saved: \(title)")

        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }

    func fetchAllAnyTasks() async throws -> [OCKAnyTask] {
        guard let store = AppDelegateKey.defaultValue?.store,
              let healthKitStore = AppDelegateKey.defaultValue?.healthKitStore else {
            throw AppError.errorString("Store not available")
        }

        let query = OCKTaskQuery(for: Date())
        let regularTasks = try await store.fetchAnyTasks(query: query)
        let healthKitTasks = try await healthKitStore.fetchAnyTasks(query: query)

        return regularTasks + healthKitTasks
    }

    func deleteAnyTask(_ task: OCKAnyTask) async throws {
        if let regularTask = task as? OCKTask {
            guard let store = AppDelegateKey.defaultValue?.store else {
                throw AppError.errorString("Store not available")
            }
            try await store.deleteAnyTask(regularTask)

        } else if let healthKitTask = task as? OCKHealthKitTask {
            guard let healthKitStore = AppDelegateKey.defaultValue?.healthKitStore else {
                throw AppError.errorString("HealthKit store not available")
            }
            try await healthKitStore.deleteAnyTask(healthKitTask)
        }

        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }

    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }

}
