//
//  TestMediaDatabase.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import SwiftUtilities
import SwiftUtilitiesTests

final class TestMediaDatabase: LocalMediaDatabase {
    override var currentAuthorizationStatus: PHAuthorizationStatus {
        return authorizationStatus
    }
    
    override var registeredMediaTypes: [MediaType] {
        return mediaTypes
    }
    
    override var registeredCollectionTypes: [MediaCollectionType] {
        return collectionTypes
    }
    
    let loadwithCollectionAndOptions: FakeDetails
    
    var authorizationStatus: PHAuthorizationStatus
    var collectionTypes: [MediaCollectionType]
    var fetchActualData: Bool
    var itemsPerAlbum: Int
    var mediaTypes: [MediaType]
    var throwRandomError: Bool
    var returnValidMedia: Bool
    
    override init() {
        loadwithCollectionAndOptions = FakeDetails.builder().build()
        authorizationStatus = .authorized
        fetchActualData = true
        itemsPerAlbum = 1000
        returnValidMedia = true
        collectionTypes = [.album, .moment, .smartAlbum]
        mediaTypes = [.audio, .image, .video]
        throwRandomError = true
        super.init()
    }
    
    override func rxa_loadMedia(from collection: PHAssetCollection,
                                with options: PHFetchOptions)
        -> Observable<AlbumResult>
    {
        loadwithCollectionAndOptions.onMethodCalled(withParameters: (collection, options))
        return super.rxa_loadMedia(from: collection, with: options)
    }
    
    override func observeFetchResult(_ result: PHFetchResult<PHAsset>,
                                     with observer: AnyObserver<PHAsset>) {
        if throwRandomError && arc4random_uniform(2) == 0 {
            observer.onError(Exception("Failed to fetch Album"))
        } else {
            if returnValidMedia {
                for _ in 0..<itemsPerAlbum {
                    observer.onNext(TestPHAsset())
                }
            }
            
            observer.onCompleted()
        }
    }
    
    override func createMedia(with asset: PHAsset, with title: String) -> LocalMedia {
        return LocalMedia.fake()
    }
}

extension TestMediaDatabase: FakeProtocol {
    func reset() {
        authorizationStatus = .authorized
        fetchActualData = true
        returnValidMedia = true
        throwRandomError = true
    }
}
