//
//  MediaDatabaseTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxTest
import XCTest

class MediaDatabaseTest: XCTestCase {
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate var mediaDatabase: TestMediaDatabase!
    fileprivate var observer: TestableObserver<Album>!
    fileprivate var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        mediaDatabase = TestMediaDatabase()
        scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(Album.self)
    }
    
    override func tearDown() {
        super.tearDown()
        mediaDatabase.reset()
    }
    
    public func test_mock_permissionNotGranted_shouldThrow() {
        // Setup
        mediaDatabase.authorizationStatus = .denied
        let expect = expectation(description: "Should have failed")
        
        // When
        _ = mediaDatabase.rxLoadAlbums()
            .doOnCompleted(expect.fulfill)
            .subscribe(observer)
        
        mediaDatabase.mediaListener.onNext(PHAssetCollection())
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        let events = observer.events
        print(events)
//        let error = events.first!.value.error
//        XCTAssertNotNil(error)
//        
//        XCTAssertEqual(error!.localizedDescription,
//                       MediaError.permissionNotGranted)
    }
}
