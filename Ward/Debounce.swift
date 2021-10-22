//
//  Debounce.swift
//  Debounce
//
//  Created by Mikhail Miasnikov on 06.09.21.
//

import SwiftUI
import Combine

class TextFieldObserver : ObservableObject {
    @Published var debouncedText: String
    @Published var searchText: String
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(text: Binding<String>  = .constant("binding")) {
        self.debouncedText = text.wrappedValue
        self.searchText = text.wrappedValue
        $searchText
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .assign(to: \.debouncedText, on: self)
            .store(in: &subscriptions)
    }
}

struct TextFieldWithDebounce : View {
    @Binding var debouncedText : String
    @StateObject private var textObserver: TextFieldObserver
    
    init(text: Binding<String>  = .constant("binding")) {
        self._debouncedText = text
        self._textObserver = StateObject(wrappedValue: .init(text: text))
    }
    
    var body: some View {
    
        VStack {
            TextField("Patienten Namen", text: $textObserver.searchText)
                .frame(height: 30)
                .padding(.leading, 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
        .onReceive(textObserver.$debouncedText) { val in
            debouncedText = val
        }
    }
}

class BloodPressureFieldObserver : ObservableObject {
    @Published var debouncedText: String
    @Published var searchText: String
    let bloodPressureCharSet = CharacterSet.init(charactersIn: "0123456789/")
    
    private var bloodPressureAsText: String {
        set {
            let valueAsText = String(newValue.unicodeScalars.filter(bloodPressureCharSet.contains))
            let splat = valueAsText.split(separator: "/")
            if splat.count == 1 {
                let systole = String(splat[0])
                debouncedText = systole.count > 3 ? String(systole.dropLast(systole.count - 3)) : systole
                debouncedText.append("/")
            } else {
                debouncedText = valueAsText.count > 7 ? String(valueAsText.dropLast(valueAsText.count - 7)) : valueAsText
            }
//            print(String(newValue.unicodeScalars.filter(bloodPressureCharSet.contains)).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        get { "" }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(text: Binding<String>  = .constant("binding")) {
        self.debouncedText = text.wrappedValue
        self.searchText = text.wrappedValue
        $searchText
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .assign(to: \.bloodPressureAsText, on: self)
            .store(in: &subscriptions)
    }
}

struct BloodPressureFieldWithDebounce : View {
    @Binding var debouncedText : String
    @Binding var isEditing: Bool
    @StateObject private var textObserver: BloodPressureFieldObserver
    
    init(text: Binding<String>  = .constant("binding"), isEditing: Binding<Bool>) {
        self._debouncedText = text
        self._isEditing = isEditing
        self._textObserver = StateObject(wrappedValue: .init(text: text))
    }
    
    var body: some View {
    
        VStack {
            TextField("Prompt", text: $textObserver.searchText)
                { isEditing in
                    self.isEditing = isEditing
                    print("qqq \(isEditing)")
                }
        }
        .onReceive(textObserver.$debouncedText) { from in
            debouncedText = from
            textObserver.objectWillChange.send()
            textObserver.searchText = debouncedText
        }
    }
}
