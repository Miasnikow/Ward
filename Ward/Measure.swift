//
//  Measure.swift
//  Measure
//
//  Created by Mikhail Miasnikov on 07.09.21.
//

import Foundation

extension Measure: Comparable {
    public static func < (lhs: Measure, rhs: Measure) -> Bool {
        lhs.probe_time ?? Date() < rhs.probe_time ?? Date()
    }
    
    public static func > (lhs: Measure, rhs: Measure) -> Bool {
        print("\(lhs.probe_time ?? Date()) > \(rhs.probe_time ?? Date())")
        return lhs.probe_time ?? Date() > rhs.probe_time ?? Date()
    }
}
