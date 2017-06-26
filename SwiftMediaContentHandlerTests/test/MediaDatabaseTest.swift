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

final class MediaDatabaseTest: XCTestCase {
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let errorProvider = DefaultMediaError()
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
        let statuses: [PHAuthorizationStatus] = [.denied, .authorized]
        let observer = scheduler.createObserver(Optional<Error>.self)
        
        // When
        mediaDatabase.databaseErrorObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        for status in statuses {
            mediaDatabase.authorizationStatus = status
            mediaDatabase.loadInitialMedia()
            
            // Then
            let nextElements = observer.nextElements()
            let lastElement = nextElements.last!
            
            switch status {
            case .denied:
                let error = lastElement.unsafelyUnwrapped
                XCTAssertEqual(error.localizedDescription, errorProvider.permissionNotGranted)
                
            case .authorized:
                XCTAssertNil(lastElement)
                
            default:
                break
            }
            
            XCTAssertTrue(mediaDatabase.loadwithCollectionAndOptions.methodNotCalled)
        }
    }
    
    public func test_fetchWithPermission_shouldSucceed() {
        // Setup
        let typeCount = mediaDatabase.mediaTypes.count
        let observer = scheduler.createObserver(TestPHAsset.self)
        let expect = expectation(description: "Should have succeeded")
        
        // When
        mediaDatabase
            .rxa_loadMedia(from: PHAssetCollection())
            .map({$0.value})
            .map({$0?.albumMedia ?? []})
            .concatMap({Observable.from($0)})
            .map({$0.value})
            .map({$0?.localAsset})
            .cast(to: TestPHAsset.self)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(mediaDatabase.loadwithCollectionAndOptions.methodCount, typeCount)
        XCTAssertEqual(nextElements.count, typeCount * mediaDatabase.itemsPerAlbum)
        
        /// Check that order is preserved
        for (index, asset) in nextElements.enumerated() {
            if index > 0 {
                let previous = nextElements[index - 1]
                XCTAssertTrue(asset.index > previous.index)
            }
        }
    }

    public func test_randomErrorThrown_shouldStillSucceed() {
        // Setup
        mediaDatabase.throwRandomError = true
        let typeCount = mediaDatabase.mediaTypes.count
        let totalTry = tries * typeCount
        let observer = scheduler.createObserver(AlbumResult.self)
        let expect = expectation(description: "Should have succeeded")
        
        // When
        Observable.range(start: 1, count: tries)
            .flatMap({_ in self.mediaDatabase.rxa_loadMedia(from: PHAssetCollection())})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        
        // Then
        XCTAssertEqual(mediaDatabase.loadwithCollectionAndOptions.methodCount, totalTry)
    }
}
