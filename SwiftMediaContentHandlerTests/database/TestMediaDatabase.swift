//
//  TestMediaDatabase.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import SwiftUtilitiesTests

class TestMediaDatabase: MediaDatabase {
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
    
    override var shouldFilterAlbumsWithoutName: Bool {
        return filterAlbumWithNoName
    }
    
    let loadAlbum_withCollectionAndOptions: FakeDetails
    
    var authorizationStatus: PHAuthorizationStatus
    var collectionTypes: [MediaCollectionType]
    var fetchActualData: Bool
    var filterEmptyAlbums: Bool
    var filterAlbumWithNoName: Bool
    var mediaTypes: [MediaType]
    var returnValidMedia: Bool
    
    override init() {
        loadAlbum_withCollectionAndOptions = FakeDetails.builder().build()
        authorizationStatus = .authorized
        fetchActualData = true
        filterEmptyAlbums = true
        filterAlbumWithNoName = true
        returnValidMedia = true
        collectionTypes = [.album, .moment, .smartAlbum]
        mediaTypes = [.audio, .image, .video]
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
        if returnValidMedia {
            observer.onNext(PHAsset())
        }
        
        observer.onCompleted()
    }
}

extension TestMediaDatabase: FakeProtocol {
    func reset() {
        authorizationStatus = .authorized
        fetchActualData = true
        filterEmptyAlbums = true
        filterAlbumWithNoName = true
        returnValidMedia = true
    }
}
