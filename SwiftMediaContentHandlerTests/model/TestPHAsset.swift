//
//  TestPHAsset.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos

class TestPHAsset: PHAsset {
    fileprivate static var counter = 0
    fileprivate static let startDate = Date()
    
    override var creationDate: Date? {
        return TestPHAsset.startDate.addingTimeInterval(TimeInterval(100 * index))
    }
    
    override var description: String {
        return "\(classForCoder)-\(String(describing: creationDate))-\(index)"
    }
    
    let index: Int
    
    override init() {
        TestPHAsset.counter += 1
        index = TestPHAsset.counter
        super.init()
    }
}
