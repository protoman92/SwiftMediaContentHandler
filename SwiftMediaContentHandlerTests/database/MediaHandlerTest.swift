//
//  MediaHandlerTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import RxTest
import RxBlocking
import XCTest

class ImageHandlerTest: XCTestCase {
    fileprivate var mediaHandler: TestMediaHandler!
    fileprivate var remoteUrl: String!
    fileprivate let expectationTimeout: TimeInterval = 5
    
    override func setUp() {
        super.setUp()
        mediaHandler = TestMediaHandler()
        mediaHandler.fetchActualData = false
        
        remoteUrl =
            "http://" +
            "vignette2.wikia.nocookie.net" +
            "/fallout/images/6/69/RadChildFNV.png/" +
            "revision/latest?cb=20101012121328"
    }
    
    override func tearDown() {
        super.tearDown()
        mediaHandler.reset()
    }
    
    func test_mock_rxLoadWebImage_shouldCallCorrectMethods() {
        // Setup
        let request = WebImageRequest.builder().with(url: remoteUrl).build()
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have worked")
        
        // When
        _ = mediaHandler
            .rxRequest(with: request)
            .doOnCompleted(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(mediaHandler.request_withWebImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withLocaImageRequest.methodNotCalled)
    }
    
    func test_mock_rxLoadLocalImage_shouldCallCorrectMethods() {
        // Setup
        let request = LocalImageRequest.builder()
            .with(media: LocalMedia.fake)
            .build()
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have worked")
        
        // When
        _ = mediaHandler.rxRequest(with: request)
            .doOnCompleted(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(mediaHandler.request_withLocaImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withWebImageRequest.methodNotCalled)
    }
}
