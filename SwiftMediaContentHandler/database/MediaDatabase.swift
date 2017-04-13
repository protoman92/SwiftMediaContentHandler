//
//  MediaDatabase.swift
//  Sellfie
//
//  Created by Hai Pham on 4/9/16.
//  Copyright © 2016 Anh Vu Mai. All rights reserved.
//

import Foundation
import Photos
import RxSwift
import SwiftUtilities

public class MediaDatabase: NSObject {
    /// Return all Album instances fetched from PHPhotoLibrary.
    public var allAlbums: [Album] {
        return albums
    }
    
    /// Return all Photo instances fetched from PHPhotoLibrary.
    public var allPhotos: [Media] {
        return allPhotos(from: albums)
    }
    
    /// We can use this imageHandler instance to cache and load images.
    public var imageHandler: MediaHandlerProtocol?
    
    /// When a Photo library change is detected, call onNext.
    fileprivate let photoLibraryListener: PublishSubject<Any>
    
    /// This Album array contains PHAsset instances that can be queried later
    /// using MediaHandler.
    fileprivate var albums = [Album]()
    
    fileprivate override init() {
        photoLibraryListener = PublishSubject<Any>()
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    /// Get all Photo instances from an albums Array.
    ///
    /// - Parameter albums: An Array of Album instances.
    /// - Returns: An Array of Photo instances.
    fileprivate func allPhotos(from albums: [Album]) -> [Media] {
        return albums.map({$0.medias}).reduce([Media](), +)
    }
    
    /// Cache full-sized images from the album Array.
    public func cacheHighQualityPhotos() {}
    
    public class Builder {
        fileprivate let database: MediaDatabase
        
        fileprivate init() {
            database = MediaDatabase()
        }
        
        /// Set the database's imageHandler instance.
        ///
        /// - Parameter imageHandler: An ImageHandler instance.
        /// - Returns: The current Builder instance.
        public func with(imageHandler: MediaHandlerProtocol) -> Builder {
            database.imageHandler = imageHandler
            return self
        }
        
        public func build() -> MediaDatabase {
            return database
        }
    }
}

public extension MediaDatabase {
    public static func builder() -> Builder {
        return Builder()
    }
}

public extension MediaDatabase {
    
    /// Load all albums from PHPhotoLibrary with an authorization status.
    public func loadAlbumWithPermission() {
        loadAlbumWithPermission(status: PHPhotoLibrary.authorizationStatus())
    }
    
    /// Load all albums from PHPhotoLibrary with an authorization status.
    ///
    /// - Parameter status: The active authorization status.
    fileprivate func loadAlbumWithPermission(status: PHAuthorizationStatus) {
        imageHandler?.checkAuthorization(status: status, completion: nil)
        
        switch status {
        case .authorized:
            loadSmartAlbumsInBackground()
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(loadAlbumWithPermission)
            
        default:
            break
        }
    }
    
    /// Load smart albums asynchronously.
    fileprivate func loadSmartAlbumsInBackground() {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            return
        }
    }
    
    /// Load smart albums.
    ///
    /// - Returns: An Observable instance.
    public func rxLoadSmartAlbums() -> Observable<Album> {
        let fetch = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil)
        
        return rxLoadAlbums(fetch: fetch)
    }
    
    /// Load albums from a PHFetchResult.
    ///
    /// - Parameter fetch: A PHFetchResult instance.
    /// - Returns: An Observable instance.
    fileprivate func rxLoadAlbums(fetch: PHFetchResult<PHAssetCollection>)
        -> Observable<Album>
    {
        let options = PHFetchOptions()
        
        options.predicate = NSPredicate(format: "mediaType = %i",
                                        PHAssetMediaType.image.rawValue)
        
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        return Observable<PHAssetCollection>
            .create({observer in
                fetch.enumerateObjects({
                    observer.onNext($0.0)
                    
                    if $0.1 == fetch.count - 1 {
                        observer.onCompleted()
                    }
                })
                
                return Disposables.create()
            })
            .flatMap({
                self.rxLoadAlbums(collection: $0, options: options)
            })
    }
    
    
    /// Load Album reactively, using a PHAssetCollection and PHFetchOptions.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to get PHAsset instances.
    ///   - options: The PHFetchOptions to use for the fetching.
    /// - Returns: An Observable instance.
    fileprivate
    func rxLoadAlbums(collection: PHAssetCollection, options: PHFetchOptions)
        -> Observable<Album>
    {
        let result = PHAsset.fetchAssets(in: collection, options: options)
            
        return Observable<PHAsset>
            .create({observer in
                result.enumerateObjects({
                    observer.onNext($0.0)
                    
                    if $0.1 == result.count - 1 {
                        observer.onCompleted()
                    }
                })
                
                return Disposables.create()
            })
            .toArray()
            .map({Album.builder()
                /// If the album does not have a title, leave empty and
                /// delegate to caller.
                .with(name: collection.localizedTitle ?? "")
                .add(assets: $0)
                .build()})
    }
}

extension MediaDatabase: PHPhotoLibraryChangeObserver {
    
    /// When media content is added or deleted, call this method.
    ///
    /// - Parameter changeInstance: A PHChange instance.
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
//        guard
//            let fetchResult = self.fetchResult,
//            let changed = changeInstance.changeDetails(for: fetchResult)
//        else {
//            return
//        }
//        
//        self.fetchResult = changed.fetchResultAfterChanges
        loadSmartAlbumsInBackground()
    }
}
