//
//  Patient.swift
//  Patient
//
//  Created by Mikhail Miasnikov on 07.09.21.
//

import Combine
import CoreData

extension Item {
    
    var measures: Set<Measure> {
        get { (measures_ as? Set<Measure> ) ?? [] }
        set { measures_ = newValue as NSSet }
    }
    
}
