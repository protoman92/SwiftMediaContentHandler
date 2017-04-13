//
//  ImageHandlerTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxSwift
import RxTest
import RxBlocking
import XCTest

class ImageHandlerTest: XCTestCase {
    fileprivate var imageHandler: TestImageHandler!
    fileprivate var remoteUrl: String!
    
    override func setUp() {
        super.setUp()
        imageHandler = TestImageHandler()
        imageHandler.fetchActualData = false
        
        remoteUrl =
            "http://" +
            "vignette2.wikia.nocookie.net" +
            "/fallout/images/6/69/RadChildFNV.png/" +
            "revision/latest?cb=20101012121328"
    }
    
    override func tearDown() {
        super.tearDown()
        imageHandler.reset()
    }
    
    func test_mock_loadImageRemotely_shouldCallCorrectMethods() {
        // Setup
        let request = ImageHandler.webRequestBuilder()
            .with(url: remoteUrl)
            .with(completion: {_,_ in})
            .build()
        
        // When
        imageHandler.request(with: request)
        
        // Then
        XCTAssertEqual(imageHandler.request_withBaseRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withWebRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withLocalRequest.methodCallCount, 0)
    }
    
    func test_mock_loadImageLocally_shouldCallCorrectMethods() {
        // Setup
        let request = ImageHandler.localRequestBuilder()
            .with(photo: Photo.blank)
            .with(completion: {_,_ in})
            .build()
        
        // When
        imageHandler.request(with: request)
        
        // Then
        XCTAssertEqual(imageHandler.request_withBaseRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withWebRequest.methodCallCount, 0)
        XCTAssertEqual(imageHandler.request_withLocalRequest.methodCallCount, 1)
    }
    
    func test_mock_rxLoadImageRemotely_shouldCallCorrectMethods() {
        // Setup
        let completion: (UIImage?, Error?) -> Void = {_,_ in
            fatalError("Should not be called")
        }
        
        let request = ImageHandler.webRequestBuilder()
            .with(url: remoteUrl)
            .with(completion: completion)
            .build()
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(UIImage.self)
        
        // When
        _ = imageHandler.rxRequest(with: request).subscribe(observer)
        scheduler.start()
        
        // Then
        XCTAssertEqual(imageHandler.request_withBaseRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withWebRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withLocalRequest.methodCallCount, 0)
    }
    
    func test_mock_rxLoadImageLocally_shouldCallCorrectMethods() {
        // Setup
        let completion: (UIImage?, Error?) -> Void = {_,_ in
            fatalError("Should not be called")
        }
        
        let request = ImageHandler.localRequestBuilder()
            .with(photo: Photo.blank)
            .with(completion: completion)
            .build()
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(UIImage.self)
        
        // When
        _ = imageHandler.rxRequest(with: request).subscribe(observer)
        scheduler.start()
        
        // Then
        XCTAssertEqual(imageHandler.request_withBaseRequest.methodCallCount, 1)
        XCTAssertEqual(imageHandler.request_withWebRequest.methodCallCount, 0)
        XCTAssertEqual(imageHandler.request_withLocalRequest.methodCallCount, 1)
    }
}
