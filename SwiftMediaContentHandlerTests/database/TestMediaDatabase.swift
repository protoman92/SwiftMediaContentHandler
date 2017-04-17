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

class TestMediaDatabase: LocalMediaDatabase {
    override var currentAuthorizationStatus: PHAuthorizationStatus {
        return authorizationStatus
    }
    
    override var registeredMediaTypes: [MediaType] {
        return mediaTypes
    }
    
    override var registeredCollectionTypes: [MediaCollectionType] {
        return collectionTypes
    }
    
    override var shouldFilterEmptyAlbums: Bool {
        return filterEmptyAlbums
    }
    
    let loadAlbum_withCollectionAndOptions: FakeDetails
    
    var authorizationStatus: PHAuthorizationStatus
    var collectionTypes: [MediaCollectionType]
    var fetchActualData: Bool
    var filterEmptyAlbums: Bool
    var includeEmptyAlbums: Bool
    var itemsPerAlbum: Int
    var mediaTypes: [MediaType]
    var throwRandomError: Bool
    var returnValidMedia: Bool
    
    override init() {
        loadAlbum_withCollectionAndOptions = FakeDetails.builder().build()
        authorizationStatus = .authorized
        fetchActualData = true
        filterEmptyAlbums = true
        includeEmptyAlbums = true
        itemsPerAlbum = 10
        returnValidMedia = true
        collectionTypes = [.album, .moment, .smartAlbum]
        mediaTypes = [.audio, .image, .video]
        throwRandomError = true
        super.init()
    }
    
    override func rxLoadAlbums(collection: PHAssetCollection,
                               options: PHFetchOptions) -> Observable<Album> {
        loadAlbum_withCollectionAndOptions
            .onMethodCalled(withParameters: (collection, options))
        
        return super.rxLoadAlbums(collection: collection, options: options)
    }
    
    override func observeFetchResult(_ result: PHFetchResult<PHAsset>,
                                     with observer: AnyObserver<PHAsset>) {
        if throwRandomError && arc4random_uniform(2) == 0 {
            observer.onError(Exception("Failed to fetch Album"))
        } else if returnValidMedia {
            for _ in 0..<itemsPerAlbum {
                observer.onNext(PHAsset())
            }
        }
        
        observer.onCompleted()
    }
    
    override func createAlbum(with collection: PHAssetCollection,
                              with assets: [PHAsset]) -> Album {
        if includeEmptyAlbums && arc4random_uniform(2) == 0 {
            return Album.empty
        } else {
            return super.createAlbum(with: collection, with: assets)
        }
    }
}

extension TestMediaDatabase: FakeProtocol {
    func reset() {
        authorizationStatus = .authorized
        fetchActualData = true
        filterEmptyAlbums = true
        includeEmptyAlbums = true
        returnValidMedia = true
        throwRandomError = true
    }
}
