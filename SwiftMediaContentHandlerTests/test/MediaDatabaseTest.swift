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
    fileprivate let tries = 100
    fileprivate var mediaDatabase: TestMediaDatabase!
    fileprivate var disposeBag: DisposeBag!
    fileprivate var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        mediaDatabase = TestMediaDatabase()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        mediaDatabase.throwRandomError = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    public func test_permissionNotGranted_shouldThrow() {
        // Setup
        mediaDatabase.authorizationStatus = .denied
        let observer = scheduler.createObserver(LocalMediaType.self)
        let expect = expectation(description: "Should have failed")
        
        // When
        mediaDatabase
            .rxa_loadMedia(from: PHAssetCollection())
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let events = observer.events
        let error = events.first!.value.error
        XCTAssertTrue(mediaDatabase.loadwithCollectionAndOptions.methodNotCalled)
        XCTAssertNotNil(error)
        XCTAssertEqual(error!.localizedDescription, permissionNotGranted)
    }
    
    public func test_fetchWithPermission_shouldSucceed() {
        // Setup
        let typeCount = mediaDatabase.mediaTypes.count
        let observer = scheduler.createObserver(LocalMediaType.self)
        let expect = expectation(description: "Should have succeeded")
        
        // When
        mediaDatabase
            .rxa_loadMedia(from: PHAssetCollection())
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(mediaDatabase.loadwithCollectionAndOptions.methodCount, typeCount)
        XCTAssertEqual(nextElements.count, typeCount * mediaDatabase.itemsPerAlbum)
    }

    public func test_mediaToAlbum_shouldSucceed() {
        // Setup
        let typeCount = mediaDatabase.mediaTypes.count
        let totalTry = tries * typeCount
        let observer = scheduler.createObserver(AlbumType.self)
        let expect = expectation(description: "Should have succeeded")
        
        // When
        /// We need to use a range due to includeEmptyAlbums using a random
        /// Bool value.
        Observable.range(start: 1, count: tries)
            .flatMap({_ in self.mediaDatabase.rxa_loadMedia(from: PHAssetCollection())})
            .cast(to: LocalMedia.self)
            .toAlbums()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(mediaDatabase.loadwithCollectionAndOptions.methodCount, totalTry)
        nextElements.forEach({XCTAssertTrue($0.count > 0)})
    }

    public func test_randomErrorThrown_shouldStillSucceed() {
        // Setup
        mediaDatabase.throwRandomError = true
        let typeCount = mediaDatabase.mediaTypes.count
        let totalTry = tries * typeCount
        let observer = scheduler.createObserver(LocalMediaType.self)
        let expect = expectation(description: "Should have succeeded")
        
        // When
        Observable.range(start: 1, count: tries)
            .flatMap({_ in self.mediaDatabase.rxa_loadMedia(from: PHAssetCollection())})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(mediaDatabase.loadwithCollectionAndOptions.methodCount, totalTry)
        nextElements.forEach({XCTAssertTrue($0.hasLocalAsset())})
    }
}

extension MediaDatabaseTest: MediaDatabaseErrorType {}
