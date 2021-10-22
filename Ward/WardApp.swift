//
//  WardApp.swift
//  Ward
//
//  Created by Mikhail Miasnikov on 06.09.21.
//

import SwiftUI

@main
struct WardApp: App {
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared
    let dateRange: Date = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2000, month: 1, day: 1)
        return calendar.date(from:startComponents)!
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(
                patientName: "Patient",
                patientBirthday: dateRange, //Date.distantPast,
                patientAddress: "",
                patientCurrentLocation: "",
                patientGender: "m/w/d",
                patientInsuranceNumber: "",
                deletedItemId: ObjectIdentifier(String.self)
            )
            .onChange(of: scenePhase) { sP in
                print("qqq \(sP)")
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
