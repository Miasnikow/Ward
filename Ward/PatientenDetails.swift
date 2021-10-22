//
//  PatientenDetails.swift
//  PatientenDetails
//
//  Created by Mikhail Miasnikov on 06.09.21.
//

import SwiftUI

struct PatientDetails: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showMeasures: Bool
    
    @Binding var patientName: String
    @Binding var birthday: Date
    @Binding var address: String
    @Binding var current_location: String
    @Binding var gender: String
    @Binding var insurance_number: String
    @Binding var deletedItemId: ObjectIdentifier
    @Binding var currentItemId: ObjectIdentifier?
    var itemId: ObjectIdentifier { itemPatient.id }
    let itemPatient: Item
    
    var body: some View {
        if itemId != deletedItemId {
        VStack {
            TextFieldWithDebounce(text: $patientName)
            TextField("Versicherungsnummer", text: $insurance_number)
            TextField("Geschlecht,", text: $gender)
            DatePicker(
                "Geburtstag",
                selection: $birthday,
                displayedComponents: [.date]
            )
            TextField("Anschrift", text: $address)
            TextField("Aktueller Aufenthalt", text: $current_location)
        }
        .frame(width: 300, height: 300)
        .navigationTitle(patientName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Messungen") {
                    self.showMeasures = true
                }
            }
        }
        .onAppear {
            currentItemId = itemId
        }
    }
    }
}

struct PatientDetail: View {
    @Binding var showMeasures: Bool
    
    @Binding var patientName: String
    @Binding var birthday: Date
    @Binding var address: String
    @Binding var current_location: String
    @Binding var gender: String
    @Binding var insurance_number: String
    @Binding var deletedItemId: ObjectIdentifier
    @Binding var currentItemId: ObjectIdentifier?
    let itemId: ObjectIdentifier
    
    var body: some View {
        if itemId != deletedItemId {
        VStack {
            TextFieldWithDebounce(text: $patientName)
            TextField("Versicherungsnummer", text: $insurance_number)
            TextField("Geschlecht", text: $gender)
            DatePicker(
                "Geburtstag",
                selection: $birthday,
                displayedComponents: [.date]
            )
            TextField("Anschrift", text: $address)
            TextField("Aktueller Aufenthalt", text: $current_location)
        }
        .frame(width: 300, height: 300)
        .navigationTitle(patientName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Messungen") {
                    self.showMeasures = true
                }
            }
        }
        .onAppear {
            currentItemId = itemId
        }
    }
    }
}
