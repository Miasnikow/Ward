//
//  MeasureManager.swift
//  MeasureManager
//
//  Created by Mikhail Miasnikov on 08.09.21.
//

import SwiftUI

class Redoing: ObservableObject, Equatable {
    static func == (lhs: Redoing, rhs: Redoing) -> Bool {
        lhs.redoing == rhs.redoing
    }
    var redoing = false
}

struct MeasureManager: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var meas: [Measure]
    @State var patientName: String
    @StateObject var redoing = Redoing()
    @State var redoo = false
    
    let itemPatient: Item
    var plusSize: CGFloat
    
    init(patientItem: FetchedResults<Item>.Element, plusSize: CGFloat) {
        self.plusSize = plusSize
        self.itemPatient = patientItem
        self.patientName = patientItem.name ?? "Patient"
        self.meas = patientItem.measures.filter { !$0.droped }
                        .sorted(by: >)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.meas) { mea in
                    if redoing.redoing == false {
                        NavigationLink {
                                            MeasurementDetails(
                                                patientName: $patientName,
                                                probeDate: Binding(
                                                    get: {
                                                        if let _ = mea.probe_time { return mea.probe_time! }
                                                        let calendar = Calendar.current
                                                        let startComponents = DateComponents(year: 2021, month: 1, day: 1)
                                                        mea.probe_time = calendar.date(from:startComponents)!
                                                        return mea.probe_time!
                                                    },
                                                    set: {
                                                        mea.probe_time = $0
                                                        try? viewContext.save()
                                                        redoing.objectWillChange.send()
                                                        redoo = true
                                                    }),
                                                patientTemperature: Binding(
                                                    get: {  mea.temperature },
                                                    set: {  mea.temperature = $0
                                                            try? viewContext.save()
                                                            redoing.objectWillChange.send()
                                                        }),
                                                patientPulse: Binding(
                                                    get: {  mea.pulse },
                                                    set: {  mea.pulse = $0
                                                            try? viewContext.save()
                                                            redoing.objectWillChange.send()
                                                        }),
                                                patientBloodPressure: Binding(
                                                    get: {  BloodPressureTest(systole: mea.blood_pressure, diastole: mea.blood_pressure_diastole)},
                                                    set: {  if let systole = $0.systole {
                                                                mea.blood_pressure = systole }
                                                            if let diastole = $0.diastole {
                                                                mea.blood_pressure_diastole = diastole }
                                                            try? viewContext.save()
                                                            redoing.objectWillChange.send()
                                                        })
                                            )
                                        }
                    label: {
                        VStack(alignment: .leading) { [mea_temperature = "\(mea.temperature, style: .decimal)", mea_systole = "\(mea.blood_pressure, style: .decimal)", mea_diastole = "\(mea.blood_pressure_diastole, style: .decimal)"] in
                            Text("Messwert-ID: \(mea.uid!)")
                                    .padding(.horizontal)
                                    .lineLimit(3)
                            Text("Temperatur: " + mea_temperature +  " Puls: \(mea.pulse, style: .none)")
                                    .padding(.horizontal)
                                    .lineLimit(3)
                            Text("Blutdruck Systole: " + mea_systole +  " Diastole: " + mea_diastole)
                                    .padding(.horizontal)
                                    .lineLimit(3)
                            VStack(alignment: .trailing) {
                                Color.clear
                                Text("PT \(mea.probe_time!, formatter: itemFormatter)")
                                    .padding(.horizontal)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }

//                        )
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Messungen verwalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    HStack {
                        #if os(iOS)
                        EditButton()
                        #endif
                        Spacer(minLength: 25)
                        Button(action: addMeasure) {
                            Label("Messungen hinzufügen", systemImage: "plus")
                                .font(.system(size: plusSize, weight: .bold, design: .rounded))
                        }
                    }
                    .font(.custom("system", size: plusSize))
            }
            .onAppear {
                if redoo {
                    print("qqq \(redoo)")
                    self.meas = self.itemPatient.measures.filter { !$0.droped } .sorted(by: >)
                    redoo.toggle()
                    redoing.objectWillChange.send()
                }
            }
        }
    .padding()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.meas[$0] }.forEach { mea in
                mea.droped = true
            }
            try? viewContext.save()
            self.meas = self.itemPatient.measures.filter { !$0.droped } .sorted(by: >)
        }
    }

    private func addMeasure() {
        let newMea = Measure(context: viewContext)
        newMea.patient = itemPatient
        newMea.timestamp = Date()
        newMea.probe_time = newMea.timestamp
        newMea.uid = UUID()
        newMea.patient_uid = itemPatient.uid
        newMea.droped = false
        try? viewContext.save()
        self.meas = self.itemPatient.measures.filter { !$0.droped }
                            .sorted(by: >)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

//struct MeasureManager_Previews: PreviewProvider {
//    static var previews: some View {
//        MeasureManager()
//    }
//}
