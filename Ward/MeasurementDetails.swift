//
//  MeasurementDetails.swift
//  MeasurementDetails
//
//  Created by Mikhail Miasnikov on 10.09.21.
//

import SwiftUI

struct MeasurementDetails: View {
    @Binding var patientName: String
    @Binding var probeDate: Date
    @Binding var patientTemperature: Double
    @Binding var patientPulse: Double
    @Binding var patientBloodPressure: BloodPressureTest
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Messungen")
            DatePicker(
                "Datum",
                selection: $probeDate,
                in: dateRange,
                displayedComponents: [.date, .hourAndMinute]
            )
            HStack {
                Text("Temperatur")
                    .modifier(MeasurementPrompt(patientMeasurement: $patientTemperature))
                Spacer(minLength: 18)
                Text("Herzschlag")
                    .modifier(MeasurementPrompt(patientMeasurement: $patientPulse))
                Spacer(minLength: 18)
                Text("Blutdruck")
                    .modifier(BloodPressureTestPrompt(patientMeasurement: $patientBloodPressure))
            }

        }
        .frame(width: 300, height: 300)
        .navigationTitle(patientName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2021, month: 1, day: 1)
        let endComponents = DateComponents(year: 2021, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return calendar.date(from:startComponents)!
            ...
            calendar.date(from:endComponents)!
    }()
    
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()
}

struct MeasurementPrompt: ViewModifier {
    @State var isEditing = false
    @State var isEditingWrong = false
    @State private var contentWidth: CGFloat?
    @Binding var patientMeasurement: Double
    
    init(patientMeasurement: Binding<Double>) {
        self._patientMeasurement = patientMeasurement
    }
    
    struct ContentWidthPreferenceKey: PreferenceKey {
            static let defaultValue: CGFloat = 0

            static func reduce(value: inout CGFloat,
                               nextValue: () -> CGFloat) {
                value = min(value, nextValue())
            }
        }
    
    func body(content: Content) -> some View {
        VStack(spacing: 4) {
            VStack(spacing: 0) {
                Group {
                    content
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(self.isEditingWrong ? Color.red : (self.isEditing ? Color.blue : Color.clear))
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ContentWidthPreferenceKey.self,
                        value: geometry.size.width
                    )
                })
                .frame(width: contentWidth)
            }
            .onPreferenceChange(ContentWidthPreferenceKey.self) { contentWidth = $0 }
            TextField("Prompt", text: Binding<String>(get: { "\(patientMeasurement, style: .decimal)" }, set: {
                let formatter: NumberFormatter = {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        return formatter
                    }()
                if let dN = formatter.number(from: $0) {
                    patientMeasurement = Double(truncating: dN)
                    self.isEditingWrong = false
                } else {
                    self.isEditingWrong = true
                }
            })) { isEditing in
                self.isEditing = isEditing
                    print("qqq \(isEditing)")
                }
//            .frame(minWidth: 50)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(self.isEditingWrong ? Color.red : (self.isEditing ? Color.blue : Color.clear), lineWidth: 1)
            )
            .keyboardType(.decimalPad)
            .frame(width: contentWidth)
        }
    }
}

struct BloodPressureTestPrompt: ViewModifier {
    @State var isEditing = false
    @State var isEditingWrong = false
    @State private var contentWidth: CGFloat?
    @Binding var patientMeasurement: BloodPressureTest
    
    init(patientMeasurement: Binding<BloodPressureTest>) {
        self._patientMeasurement = patientMeasurement
    }
    
    struct ContentWidthPreferenceKey: PreferenceKey {
            static let defaultValue: CGFloat = 0

            static func reduce(value: inout CGFloat,
                               nextValue: () -> CGFloat) {
                value = min(value, nextValue())
            }
        }
    
    func body(content: Content) -> some View {
        VStack(spacing: 4) {
            VStack(spacing: 0) {
                Group {
                    content
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(self.isEditingWrong ? Color.red : (self.isEditing ? Color.blue : Color.clear))
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ContentWidthPreferenceKey.self,
                        value: geometry.size.width
                    )
                })
                .frame(width: contentWidth)
            }
            .onPreferenceChange(ContentWidthPreferenceKey.self) { contentWidth = $0 }
            BloodPressureFieldWithDebounce(text: Binding<String>(get: { "\(patientMeasurement)" }, set: {
                let formatter = BloodPressureFormatter()
                if let dN = formatter.numbers(from: $0) {
                    patientMeasurement = dN
                    self.isEditingWrong = false
                } else {
                    self.isEditingWrong = true
                }
                }), isEditing: $isEditing)
//            .frame(minWidth: 50)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(self.isEditingWrong ? Color.red : (self.isEditing ? Color.blue : Color.clear), lineWidth: 1)
            )
            .keyboardType(.decimalPad)
            .frame(width: contentWidth)
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ number: Double, style: NumberFormatter.Style = .decimal) {
        let formatter = NumberFormatter()
        formatter.numberStyle = style

        if let result = formatter.string(from: number as NSNumber) {
            appendLiteral(result)
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ number: BloodPressureTest) {
        let formatter = BloodPressureFormatter()

        if let result = formatter.stringFor(number) {
            appendLiteral(result)
        }
    }
}

class BloodPressureTestNil {
    fileprivate init() {}
}

class BloodPressureTest {
    let systole: Double?
    let diastole: Double?
    
    init(systole: Double? = nil, diastole: Double? = nil) {
        self.systole = systole
        self.diastole = diastole
    }
}

func stringToBloodPressureTest(from: String) -> BloodPressureTest? {
//    let bloodPressureCharSet = CharacterSet.init(charactersIn: "0123456789/")
//    print(String(from.unicodeScalars.filter(bloodPressureCharSet.contains)).trimmingCharacters(in: .whitespacesAndNewlines))
    let splat = from.split(separator: "/")
    
    if splat.count == 0 {
        return BloodPressureTest(systole: 0, diastole: 0)
    }
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()
    if splat.count == 1 {
        if let systole = formatter.number(from: String(splat[0])) {
            return BloodPressureTest(systole: Double(truncating: systole), diastole: 0)
        }
    }
    if let systole = formatter.number(from: String(splat[0])), let diastole = formatter.number(from: String(splat[1])) {
        return BloodPressureTest(systole: Double(truncating: systole), diastole: Double(truncating: diastole))
    }
    return nil
}

class BloodPressureFormatter: Formatter {
    
    public func numbers(from bloodPressureTestAsString: String) -> BloodPressureTest? {
            var bloodPressureTest: AnyObject?
            getObjectValue(&bloodPressureTest, for: bloodPressureTestAsString, errorDescription: nil)
            return bloodPressureTest as? BloodPressureTest
        }
    
    public func stringFor(_ bloodPressureTest: BloodPressureTest) -> String? {
        return string(for: bloodPressureTest)
    }
    
    override func string(for obj: Any?) -> String? {
        if let bloodPressureTest = obj as? BloodPressureTest, let bloodPressureTestSystole = bloodPressureTest.systole, let bloodPressureTestDiastole = bloodPressureTest.diastole {
            if bloodPressureTestSystole != 0 && bloodPressureTestDiastole != 0 {
                return "\(bloodPressureTestSystole, style: .decimal)/\(bloodPressureTestDiastole, style: .decimal)"
            }
            if bloodPressureTestSystole == 0 && bloodPressureTestDiastole == 0 {
                return ""
            }
            if bloodPressureTestSystole == 0 {
                return "/\(bloodPressureTestDiastole, style: .decimal)"
            }
            if bloodPressureTestDiastole == 0 {
                return "\(bloodPressureTestSystole, style: .decimal)/"
            }
        }
        return nil
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if let bloodPressureTest = stringToBloodPressureTest(from: string) {
            obj?.pointee = bloodPressureTest
            return true
        }
        obj?.pointee = BloodPressureTestNil() as AnyObject
        return true
    }
}

//struct MeasurementDetails_Previews: PreviewProvider {
//    static var previews: some View {
//        MeasurementDetails()
//    }
//}


