//
//  ContentView.swift
//  Ward
//
//  Created by Mikhail Miasnikov on 06.09.21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    
    private var items: FetchedResults<Item>
    
    @State var patientName: String
    @State var patientBirthday: Date
    @State var patientAddress: String
    @State var patientCurrentLocation: String
    @State var patientGender: String
    @State var patientInsuranceNumber: String
    @State var deletedItemId: ObjectIdentifier
    @State var currentItemId: ObjectIdentifier?
    
    @State private var showMeasures = false
    @State var isEditMode: EditMode = .inactive
    @State var isLoading: Bool = false
    @State var isRotating: Bool = false
    @State var isEditing: Bool = false
    
    private let threshold: CGFloat = 100.0
    @ScaledMetric
    var plusSize: CGFloat = 32.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                List {
                    if let _ = print("loading \(isLoading)") {}
                    Color.clear
                        .overlay(Text(!isEditing ? "Zum Update nach unten ziehen." : "Bearbeitungsmodus"), alignment: .topLeading)
                        .anchorPreference(key: OffsetPreferenceKey.self, value: .top) {
                            abs(geometry[$0].y)
                        }
                    if isLoading {
                        Color.clear
                            .onAppear {
                                if !isRotating {
                                    withAnimation(Animation.linear(duration: 0.75).repeatForever(autoreverses: false)) {
                                        isRotating.toggle()
                                    }
                                }
                            }
                            .onDisappear {
                                if isRotating {
                                    isRotating.toggle()
                                }
                            }
                            .overlay(Image.init(systemName: "hourglass")
                                        .resizable()
                                        .frame(width: 15, height: 20, alignment: .center)
                                        .modifier(Waitify(onRotation: isRotating)))
//                        .overlay(ProgressView().opacity(isRotating ? 1 : 0 ).progressViewStyle(DarkBlueShadowProgressViewStyle()))
                    }
                    ForEach(items) { item in
                        NavigationLink {
                                        PatientDetail(
                                            showMeasures: $showMeasures,
                                            patientName: Binding(
                                                get: {
                                                    if let _ = item.name { return item.name! }
                                                    return ""
                                                },
                                                set: {
                                                    item.name = $0
                                                    try? viewContext.save()
                                                }),
                                            birthday: Binding(
                                                get: {
                                                    if let _ = item.birthday { return item.birthday! }
                                                    return patientBirthday
                                                },
                                                set: {
                                                    item.birthday = $0
                                                    try? viewContext.save()
                                                }),
                                            address: Binding(
                                                get: {
                                                    if let _ = item.address { return item.address! }
                                                    return patientAddress
                                                },
                                                set: {
                                                    item.address = $0
                                                    try? viewContext.save()
                                                }),
                                            current_location: Binding(
                                                get: {
                                                    if let _ = item.current_location { return item.current_location! }
                                                    return patientCurrentLocation
                                                },
                                                set: {
                                                    item.current_location = $0
                                                    try? viewContext.save()
                                                }),
                                            gender: Binding(
                                                get: {
                                                    if let _ = item.gender { return item.gender! }
                                                    return patientGender
                                                },
                                                set: {
                                                    item.gender = $0
                                                    try? viewContext.save()
                                                }),
                                            insurance_number: Binding(
                                                get: {
                                                    if let _ = item.insurance_number { return item.insurance_number! }
                                                    return patientInsuranceNumber
                                                },
                                                set: {
                                                    item.insurance_number = $0
                                                    try? viewContext.save()
                                                }),
                                            deletedItemId: $deletedItemId,
                                            currentItemId: $currentItemId,
                                            itemId: item.id
                                        )
                                       }
                    label: {
                        VStack(alignment: .leading) {
                            Text("\(nameOfPatient(from: item.name)) (\(item.gender ?? patientGender), \(agePatient(item.birthday)) j.)")
                                .padding(.horizontal)
                            VStack(alignment: .trailing) {
                                Color.clear
                                Text("\(item.current_location ?? patientCurrentLocation)")
                                    .padding(.horizontal)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                }
                .onDelete(perform: deleteItems)
                .onChange(of: isEditMode) { eM in
                    if eM == .active && !isEditing {
                        withAnimation(Animation.linear(duration: 1)) {
                            isEditing.toggle()
                            items.first?.objectWillChange.send()
                        }
                    }
                    if eM == .inactive {
                        isEditing = false
                        try? viewContext.save()
                    }
                }
            }
            .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                if offset > threshold && !isEditing {
                    print("qqq1 \(offset)")
                    refreshList()
                }
            }
            .navigationTitle("Patienten verwalten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                HStack {
                    #if os(iOS)
                    EditButton()
                    #endif
                    Spacer(minLength: 25)
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                            .font(.system(size: plusSize, weight: .bold, design: .rounded))
                    }
                }
                .font(.custom("system", size: plusSize))
            }
//            .font(.system(size: plusSize, weight: .bold, design: .rounded))
            .environment(\.editMode, self.$isEditMode)
        }
        }
        .sheet(isPresented: $showMeasures) {
            if self.items.filter { $0.id == self.currentItemId }.first != nil {
                MeasureManager(patientItem: self.items.filter { $0.id == self.currentItemId }.first!, plusSize: plusSize)
            }
        }
        .environment(\.managedObjectContext, viewContext)
    }
    
    private func addItem() {
        withAnimation(Animation.linear(duration: 1)) {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.uid = UUID()
            try? viewContext.save()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        isEditing = true
        if viewContext.hasChanges {
            isEditMode = .inactive
            try? viewContext.save()
        } else {
        let off = offsets.filter { $0 < items.indices.endIndex } .reversed()
        off.map { items[$0] } .forEach { item in
                    if self.currentItemId == item.id {
                        self.deletedItemId = item.id
                        self.currentItemId = nil
                    }
            item.objectWillChange.send()
//            item.measures = []
        }
        withAnimation(Animation.linear(duration: 1)) {
            off.map { items[$0] } .forEach { item in
                viewContext.delete(item)
            }
        }
            try? viewContext.save()
        }
    }
    
    private func refreshList() {
        if !isLoading {
            withAnimation(Animation.linear(duration: 1)) {
                isLoading.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
            }
        }
    }
    
    func agePatient(_ birthdate: Date?) -> Int {
        guard let birthdate = birthdate else {
            return 0
        }
        let calendar = Calendar.current
        let birthDay = calendar.dateComponents([.year, .month, .day], from: birthdate)
        let now = calendar.dateComponents([.year, .month, .day], from: Date())
        let ageComponents = calendar.dateComponents([.year], from: birthDay, to: now)
        return ageComponents.year!
    }
    
    func nameOfPatient(from defaultName: String?) -> String {
        let placeHolder = ""
        if let defaultName = defaultName, let components = patientNameFormatter.personNameComponents(from: defaultName) {
            print(components)
            /* Prints:
               namePrefix: Sir
               givenName: David
               middleName: Frederick
               familyName: Attenborough
            */
            return "\(components.familyName ?? placeHolder), \(components.givenName ?? placeHolder)"
        }
        return self.patientName
    }
    
    private let patientNameFormatter = PersonNameComponentsFormatter()
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
}

fileprivate struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

fileprivate struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?

    static var defaultValue: Value = nil

    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value = nextValue()
    }
}

fileprivate struct SizePreferences<Item: Hashable>: PreferenceKey {
    typealias Value = [Item: CGSize]

    static var defaultValue: Value { [:] }

    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value.merge(nextValue()) { $1 }
    }
}

fileprivate struct Waitify: AnimatableModifier {
    
    init(onRotation: Bool) {
        rotation = onRotation ? 0 : 360
    }
    
    var rotation: Double
    
    var animatableData: Double {
        get {
            rotation
        }
        set {
            rotation = newValue
        }
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(Angle.degrees(rotation), axis: (x: 0, y: 0, z: 1))
    }
}

struct DarkBlueShadowProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
            ProgressView(configuration)
                .scaleEffect(2)
                .shadow(color: Color(red: 0, green: 0, blue: 0.6),
                    radius: 4.0, x: 1.0, y: 2.0)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(patientName: "Patient", patientBirthday: Date(), patientAddress: "Patient", patientCurrentLocation: "Patient", patientGender: "Patient", patientInsuranceNumber: "Patient", deletedItemId: ObjectIdentifier(String.self)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
