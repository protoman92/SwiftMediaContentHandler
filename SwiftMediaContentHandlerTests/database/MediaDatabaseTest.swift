//
//  MediaDatabaseTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxTest
import RxSwift
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
        mediaDatabase.includeEmptyAlbums = false
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
        _ = mediaDatabase
            .rxLoadAlbums(collection: PHAssetCollection())
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        XCTAssertTrue(
            mediaDatabase.loadAlbum_withCollectionAndOptions.methodNotCalled
        )
        
        let events = observer.events
        let error = events.first!.value.error
        XCTAssertNotNil(error)
        
        XCTAssertEqual(error!.localizedDescription,
                       MediaError.permissionNotGranted)
    }
    
    public func test_mock_fetchWithPermission_shouldSucceed() {
        // Setup
        let typeCount = mediaDatabase.mediaTypes.count
        let expect = expectation(description: "Should have succeeded")
        
        // When
        _ = mediaDatabase
            .rxLoadAlbums(collection: PHAssetCollection())
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        XCTAssertEqual(
            mediaDatabase.loadAlbum_withCollectionAndOptions.methodCount,
            typeCount
        )
        
        let events = observer.events
        let nextValues = events[0..<typeCount].flatMap({$0.value.element})
        XCTAssertEqual(nextValues.count, typeCount)
    }
    
    public func test_mock_filterEmptyAlbums_shouldSucceed() {
        // Setup
        mediaDatabase.includeEmptyAlbums = true
        let tries = 10
        let typeCount = mediaDatabase.mediaTypes.count
        let totalTry = tries * typeCount
        let expect = expectation(description: "Should have succeeded")
        
        // When
        /// We need to use a range due to includeEmptyAlbums using a random
        /// Bool value.
        _ = Observable.range(start: 1, count: tries)
            .flatMap({_ in self.mediaDatabase
                .rxLoadAlbums(collection: PHAssetCollection())})
            .filter({$0.isNotEmpty})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
        
        scheduler.start()
        
        // Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        XCTAssertEqual(
            mediaDatabase.loadAlbum_withCollectionAndOptions.methodCount,
            totalTry
        )
        
        let events = observer.events
        let count = events.count
        let nextValues = events[0..<count - 1].flatMap({$0.value.element})
        XCTAssertLessThanOrEqual(nextValues.count, totalTry)
    }
}
