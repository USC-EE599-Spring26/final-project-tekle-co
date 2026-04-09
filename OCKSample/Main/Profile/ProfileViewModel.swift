import CareKit
import CareKitStore
import CareKitEssentials
import ParseSwift
import SwiftUI
import UIKit
import os.log
import HealthKit

// swiftlint:disable type_body_length
@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: Public read/write properties
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthday = Date()
    @Published var sex: OCKBiologicalSex = .other("other")
    @Published var sexOtherField = "other"
    @Published var note = ""
    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipcode = ""
    @Published var country = ""
    @Published var allergies = ""
    @Published var emailAddress = ""
    @Published var phoneNumber = ""
    @Published var messagingNumber = ""
    @Published var otherContactInfo = ""
    @Published var isShowingSaveAlert = false
    @Published var isPresentingAddTask = false
    @Published var isPresentingContact = false
    @Published var isPresentingImagePicker = false
    @Published var profileUIImage: UIImage? = UIImage(systemName: "person.fill") {
        willSet {
            guard let inputImage = newValue else {
                return
            }
            if let currentImage = self.profileUIImage, currentImage === inputImage {
                return
            }
            if !isSettingProfilePictureForFirstTime {
                Task {
                    guard var currentUser = (try? await User.current()),
                          let image = inputImage.jpegData(compressionQuality: 0.25) else {
                        Logger.profile.error("User is not logged in or could not compress image")
                        return
                    }
                    let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
                    currentUser = currentUser.set(\.profilePicture, to: newProfilePicture)
                    do {
                        _ = try await currentUser.save()
                        Logger.profile.info("Saved updated profile picture successfully.")
                    } catch {
                        Logger.profile.error("Could not save profile picture: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    @Published private(set) var error: Error?
    private(set) var alertMessage = "All changes saved successfully!"
    private var contact: OCKContact?
    private var isSettingProfilePictureForFirstTime = true

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

    // MARK: Helpers (public)
    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient,
              patient.uuid != self.patient?.uuid else {
            return
        }
        self.patient = patient
        Task {
            do {
                try await fetchProfilePicture()
            } catch {
                Logger.profile.error("Failed to fetch profile picture: \(error.localizedDescription)")
            }
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
        emailAddress = contact.emailAddresses?.first?.value ?? ""
        phoneNumber = contact.phoneNumbers?.first?.value ?? ""
        messagingNumber = contact.messagingNumbers?.first?.value ?? ""
        otherContactInfo = contact.otherContactInfo?.first?.value ?? ""
    }

    @MainActor
    private func fetchProfilePicture() async throws {
        guard let currentUser = (try? await User.current().fetch()) else {
            Logger.profile.error("User is not logged in")
            return
        }
        if let pictureFile = currentUser.profilePicture {
            do {
                let profilePicture = try await pictureFile.fetch()
                guard let path = profilePicture.localURL?.relativePath else {
                    Logger.profile.error("Could not find relative path for profile picture.")
                    return
                }
                self.profileUIImage = UIImage(contentsOfFile: path)
            } catch {
                Logger.profile.error("Could not fetch profile picture: \(error.localizedDescription).")
            }
        }
        self.isSettingProfilePictureForFirstTime = false
    }

    // MARK: User intentional behavior
    @MainActor
    func saveProfile() async {
        alertMessage = "All changes saved successfully!"
        do {
            try await savePatient()
            try await saveContact()
        } catch {
            alertMessage = "Could not save profile: \(error)"
        }
        isShowingSaveAlert = true
    }

    @MainActor
    func savePatient() async throws {
        if var patientToUpdate = patient {
            var patientHasBeenUpdated = false
            if patient?.name.givenName != firstName {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = firstName
            }
            if patient?.name.familyName != lastName {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = lastName
            }
            if patient?.birthday != birthday {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birthday
            }
            if patient?.sex != sex {
                patientHasBeenUpdated = true
                patientToUpdate.sex = sex
            }
            let notes = [OCKNote(author: firstName,
                                 title: "New Note",
                                 content: note)]
            if patient?.notes != notes {
                patientHasBeenUpdated = true
                patientToUpdate.notes = notes
            }
            if patient?.allergies?.first != allergies {
                patientHasBeenUpdated = true
                patientToUpdate.allergies = [allergies]
            }
            if patientHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
            }
        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }
            var newPatient = OCKPatient(id: remoteUUID,
                                        givenName: firstName,
                                        familyName: lastName)
            newPatient.birthday = birthday
            _ = try await AppDelegateKey.defaultValue?.store.addAnyPatient(newPatient)
            Logger.profile.info("Successfully saved new patient")
        }
    }

    @MainActor
    func saveContact() async throws {
        if var contactToUpdate = contact {
            var contactHasBeenUpdated = false
            if let patientName = patient?.name,
                contact?.name != patient?.name {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
            }
            let potentialAddress = OCKPostalAddress(
                street: street,
                city: city,
                state: state,
                postalCode: zipcode,
                country: country
            )
            if contact?.address != potentialAddress {
                contactHasBeenUpdated = true
                contactToUpdate.address = potentialAddress
            }
            if contact?.emailAddresses?.first?.value != emailAddress {
                contactHasBeenUpdated = true
                contactToUpdate.emailAddresses = [OCKLabeledValue(label: "email", value: emailAddress)]
            }
            if contact?.phoneNumbers?.first?.value != phoneNumber {
                contactHasBeenUpdated = true
                contactToUpdate.phoneNumbers = [OCKLabeledValue(label: "phone", value: phoneNumber)]
            }
            if contact?.messagingNumbers?.first?.value != messagingNumber {
                contactHasBeenUpdated = true
                contactToUpdate.messagingNumbers = [OCKLabeledValue(label: "messaging", value: messagingNumber)]
            }
            if contact?.otherContactInfo?.first?.value != otherContactInfo {
                contactHasBeenUpdated = true
                contactToUpdate.otherContactInfo = [OCKLabeledValue(label: "other", value: otherContactInfo)]
            }

            if contactHasBeenUpdated {
                _ = try await AppDelegateKey.defaultValue?.store.updateAnyContact(contactToUpdate)
                Logger.profile.info("Successfully updated contact")
            }

        } else {
            guard let remoteUUID = (try? await Utility.getRemoteClockUUID())?.uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }
            guard let patientName = self.patient?.name else {
                Logger.profile.info("The patient did not have a name.")
                return
            }
            let newContact = OCKContact(
                id: remoteUUID,
                name: patientName,
                carePlanUUID: nil
            )
            _ = try await AppDelegateKey.defaultValue?.store.addAnyContact(newContact)
            Logger.profile.info("Successfully saved new contact")
        }
    }

    static func queryPatient() -> OCKPatientQuery {
        OCKPatientQuery(for: Date())
    }

    static func queryContacts() -> OCKContactQuery {
        OCKContactQuery(for: Date())
    }

    // MARK: Partner's existing methods - kept as is
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
            text: nil
        )
        var task = OCKTask(
            id: UUID().uuidString,
            title: title,
            carePlanUUID: nil,
            schedule: schedule
        )
        task.instructions = instructions
        _ = try await store.addAnyTask(task)
        Logger.profile.info("Task saved successfully: \(title)")
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
        _ = try await store.addAnyTask(task)
        Logger.profile.info("HealthKit Task saved: \(title)")
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
}
