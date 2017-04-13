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
    fileprivate var mediaHandler: TestMediaHandler!
    fileprivate var remoteUrl: String!
    
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
    
    func test_mock_loadWebImage_shouldCallCorrectMethods() {
        // Setup
        let request = WebImageRequest.builder().with(url: remoteUrl).build()
        
        // When
        mediaHandler.requestMedia(with: request, andThen: {_,_ in})
        
        // Then
        XCTAssertEqual(mediaHandler.request_withBaseRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withWebRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withWebImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withLocalRequest.methodNotCalled)
        XCTAssertTrue(mediaHandler.request_withLocaImageRequest.methodNotCalled)
    }
    
    func test_mock_loadLocalImage_shouldCallCorrectMethods() {
        // Setup
        let request = LocalImageRequest.builder().with(media: Media.blank).build()
        
        // When
        mediaHandler.requestMedia(with: request, andThen: {_,_ in})
        
        // Then
        XCTAssertEqual(mediaHandler.request_withBaseRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withLocalRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withLocaImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withWebRequest.methodNotCalled)
        XCTAssertTrue(mediaHandler.request_withWebImageRequest.methodNotCalled)
    }
    
    func test_mock_rxLoadWebImage_shouldCallCorrectMethods() {
        // Setup
        let request = WebImageRequest.builder().with(url: remoteUrl).build()
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Any.self)
        
        // When
        _ = mediaHandler.rxRequest(with: request).subscribe(observer)
        scheduler.start()
        
        // Then
        XCTAssertEqual(mediaHandler.rxRequest_withBaseRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withBaseRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withWebRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withWebImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withLocalRequest.methodNotCalled)
        XCTAssertTrue(mediaHandler.request_withLocaImageRequest.methodNotCalled)
    }
    
    func test_mock_rxLoadLocalImage_shouldCallCorrectMethods() {
        // Setup
        let request = LocalImageRequest.builder().with(media: Media.blank).build()
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Any.self)
        
        // When
        _ = mediaHandler.rxRequest(with: request).subscribe(observer)
        scheduler.start()
        
        // Then
        XCTAssertEqual(mediaHandler.rxRequest_withBaseRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withLocalRequest.methodCount, 1)
        XCTAssertEqual(mediaHandler.request_withLocaImageRequest.methodCount, 1)
        XCTAssertTrue(mediaHandler.request_withWebRequest.methodNotCalled)
        XCTAssertTrue(mediaHandler.request_withWebImageRequest.methodNotCalled)
    }
}
