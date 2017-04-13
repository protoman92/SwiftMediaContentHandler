//
//  TestImageHandler.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities
import SwiftUtilitiesTests

class TestImageHandler: ImageHandler {
    let request_withBaseRequest: FakeDetails
    
    override init() {
        request_withBaseRequest = FakeDetails.builder().build()
        super.init()
    }
    
    override func request(with request: ImageHandler.Request) {
        super.request(with: request)
    }
}
