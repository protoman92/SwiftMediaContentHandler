//
//  ImageHandlerTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import XCTest

class ImageHandlerTest: XCTestCase {
    fileprivate var imageHandler: ImageHandler!
    fileprivate var remoteUrl: String!
    
    override func setUp() {
        super.setUp()
        imageHandler = ImageHandler.builder().build()
        
        remoteUrl =
            "http://" +
            "vignette2.wikia.nocookie.net" +
            "/fallout/images/6/69/RadChildFNV.png/" +
            "revision/latest?cb=20101012121328"
    }
    
    func test_loadImageWithRequest_shouldCallCorrectMethod() {
        // Setup
        
        // When
        
        // Then
    }
    
    func test_actual_loadImageRemotely_shouldSucceed() {
        // Setup
        let completion: (UIImage?, Error?) -> Void = {
            XCTAssertNotNil($0.0)
            XCTAssertNil($0.1)
        }
        
        let request = ImageHandler.webRequestBuilder()
            .with(url: remoteUrl)
            .with(completion: completion)
            .build()
        
        // When
        imageHandler.request(with: request)
        
        // Then
    }
}
