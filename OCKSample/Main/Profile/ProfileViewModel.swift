import CareKit
import CareKitStore
import CareKitEssentials
import SwiftUI
import os.log

@MainActor
class ProfileViewModel: ObservableObject {

    var firstName = ""
    var lastName = ""
    var birthday = Date()

    var patient: OCKPatient? {
        willSet {
            if let currentFirstName = newValue?.name.givenName {
                firstName = currentFirstName
            }
            if let currentLastName = newValue?.name.familyName {
                lastName = currentLastName
            }
            if let currentBirthday = newValue?.birthday {
                birthday = currentBirthday
            }
        }
    }

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient else {
            return
        }
        self.patient = patient
    }

    func saveProfile() async throws {

        guard var patientToUpdate = patient else {
            throw AppError.errorString("The profile is missing the Patient")
        }

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

        if patientHasBeenUpdated {
            if let anyPatient = try await AppDelegateKey.defaultValue?.store.updateAnyPatient(patientToUpdate),
               let updatedPatient = anyPatient as? OCKPatient {
                self.patient = updatedPatient
                Logger.profile.info("Successfully updated patient and synced local state.")
            } else {
                Logger.profile.error("Patient was updated in store but could not be cast to OCKPatient.")
            }
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

        print("✅ Task saved successfully: \(title)")

        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }
    
    func fetchAllTasks() async throws -> [OCKTask] {
        guard let store = AppDelegateKey.defaultValue?.store else {
            throw AppError.errorString("Store not available")
        }
        let query = OCKTaskQuery(for: Date())
        let tasks = try await store.fetchTasks(query: query)
        return tasks
    }

    func deleteTask(_ task: OCKTask) async throws {
        guard let store = AppDelegateKey.defaultValue?.store else {
            throw AppError.errorString("Store not available")
        }
        
        try await store.deleteAnyTask(task)
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.shouldRefreshView),
            object: nil
        )
    }
    
}
