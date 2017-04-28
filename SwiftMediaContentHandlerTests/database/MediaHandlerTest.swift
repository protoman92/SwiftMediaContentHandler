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

class MediaHandlerTest: XCTestCase {
    fileprivate var mediaHandler: TestMediaHandler!
    fileprivate var remoteImageUrl: String!
    fileprivate var observer: TestableObserver<Any>!
    fileprivate var scheduler: TestScheduler!
    fileprivate let expectationTimeout: TimeInterval = 5
    
    override func setUp() {
        super.setUp()
        mediaHandler = TestMediaHandler()
        mediaHandler.fetchActualData = false
        
        scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(Any.self)
        
        remoteImageUrl =
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
        let request = WebImageRequest.builder().with(url: remoteImageUrl).build()
        let expect = expectation(description: "Should have worked")
        
        // When
        _ = mediaHandler
            .rxRequest(with: request)
            .doOnDispose(expect.fulfill)
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
        
        let expect = expectation(description: "Should have worked")
        
        // When
        _ = mediaHandler.rxRequest(with: request)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)

        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(mediaHandler.request_withLocaImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withWebImageRequest.methodNotCalled)
    }
    
    func test_rxLoadLocalImageWithNoMedia_shouldThrow() {
        // Setup
        mediaHandler.fetchActualData = true
        
        let request = LocalImageRequest.builder()
            .with(media: LocalMedia.noMedia)
            .build()
        
        let expect = expectation(description: "Should have failed")
        
        // When
        _ = mediaHandler.rxRequest(with: request)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(mediaHandler.request_withLocaImageRequest.methodCount, 1)
        
        let events = observer.events
        print(events)
        let error = events.first!.value.error
        XCTAssertNotNil(error)
        XCTAssertEqual(error!.localizedDescription, mediaUnavailable)
    }
    
    func test_mock_notAuthorizedLocally_shouldThrow() {
        // Setup
        mediaHandler.isPhotoAccessAuthorized = false
        let request = LocalRequest.localBuilder().build()
        let expect = expectation(description: "Should have failed")
        
        // When
        _ = mediaHandler
            .rxRequest(with: request)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(mediaHandler.request_withLocaImageRequest.methodNotCalled)
        
        let events = observer.events
        let error = events.first!.value.error
        XCTAssertNotNil(error)
        
        XCTAssertEqual(error!.localizedDescription,
                       permissionNotGranted)
    }
    
    func test_mock_unknownRequestType_shouldThrow() {
        // Setup
        let request = MediaRequest.baseBuilder().build()
        let expect = expectation(description: "Should have failed")
        
        // When
        _ = mediaHandler
            .rxRequest(with: request)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        let events = observer.events
        let error = events.first!.value.error
        XCTAssertNotNil(error)
        
        XCTAssertEqual(error!.localizedDescription,
                       mediaHandlerUnknownRequest)
    }
    
    func test_mock_mediaUnavailable_shouldThrow() {
        // Setup
        mediaHandler.returnValidMedia = false
        let request = LocalImageRequest.builder().build()
        let expect = expectation(description: "Should have failed")
        
        // When
        _ = mediaHandler
            .rxRequest(with: request)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        let events = observer.events
        let error = events.first!.value.error
        XCTAssertNotNil(error)
        XCTAssertEqual(error!.localizedDescription, mediaUnavailable)
    }
}

extension MediaHandlerTest: MediaErrorType {}
