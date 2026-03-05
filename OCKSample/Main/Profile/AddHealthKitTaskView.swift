//
//  AddHealthKitTaskView.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 3/5/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKitStore
import HealthKit

struct AddHealthKitTaskView: View {

    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var instructions = ""
    @State private var hour = 8
    @State private var selectedQuantityType = HKQuantityTypeIdentifier.activeEnergyBurned
    @State private var selectedUnit = HKUnit.count()
    @State private var assetName = ""

    @ObservedObject var viewModel: ProfileViewModel

    struct HealthKitTypeOption: Identifiable {
        let id = UUID()
        let label: String
        let identifier: HKQuantityTypeIdentifier
        let unit: HKUnit
    }

    let quantityTypes: [HealthKitTypeOption] = [
        HealthKitTypeOption(label: "Active Energy", identifier: .activeEnergyBurned, unit: .kilocalorie()),
        HealthKitTypeOption(label: "Sleep", identifier: .appleSleepingWristTemperature, unit: HKUnit.degreeCelsius())
    ]

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Task Info")) {
                    TextField("Title", text: $title)
                    TextField("Instructions", text: $instructions)
                    TextField("Asset", text: $assetName)
                    Stepper("Hour: \(hour)", value: $hour, in: 0...23)
                }

                Section(header: Text("HealthKit Type")) {
                    Picker("Quantity Type", selection: $selectedQuantityType) {
                        ForEach(quantityTypes) { item in
                            Text(item.label).tag(item.identifier)
                        }
                    }
                    .onChange(of: selectedQuantityType) { newValue in
                        if let match = quantityTypes.first(where: { $0.identifier == newValue }) {
                            selectedUnit = match.unit
                        }
                    }
                }

                Section {
                    Button("Save HealthKit Task") {
                        Task {
                            do {
                                try await viewModel.createHealthKitTask(
                                    title: title,
                                    instructions: instructions,
                                    hour: hour,
                                    quantityIdentifier: selectedQuantityType,
                                    unit: selectedUnit,
                                    assetName: assetName.isEmpty ? "globe" : assetName
                                )
                                dismiss()
                            } catch {
                                print("Error saving HealthKit task: \(error)")
                            }
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add HealthKit Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
