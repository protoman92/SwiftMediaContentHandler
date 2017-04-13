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
    public var allPhotos: [Photo] {
        return allPhotos(from: albums)
    }
    
    /// We can use this imageHandler instance to cache and load images.
    public var imageHandler: ImageHandlerProtocol?
    
    fileprivate var albums = [Album]() {
        willSet {
            imageHandler?.stopAssetCache()
        }
        
        didSet {
            imageHandler?.cache(assets: allPhotos(from: albums),
                                targetSize: ImageSize.SQUARED_MEDIUM)
        }
    }
    
    /// A PHFetchResult instance.
    fileprivate var fetchResult: PHFetchResult<PHAssetCollection>?
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    /// Get all Photo instances from an albums Array.
    ///
    /// - Parameter albums: An Array of Album instances.
    /// - Returns: An Array of Photo instances.
    fileprivate func allPhotos(from albums: [Album]) -> [Photo] {
        return albums.map({$0.photos}).reduce([Photo](), +)
    }
    
    /// Cache full-sized images from the album Array.
    public func cacheHighQualityPhotos() {
        imageHandler?.cache(assets: allPhotos(from: albums),
                            targetSize: ImageSize.SQUARED_FULL)
    }
    
    public class Builder {
        fileprivate let database: MediaDatabase
        
        fileprivate init() {
            database = MediaDatabase()
        }
        
        /// Set the database's imageHandler instance.
        ///
        /// - Parameter imageHandler: An ImageHandler instance.
        /// - Returns: The current Builder instance.
        public func with(imageHandler: ImageHandlerProtocol) -> Builder {
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
        
        background(.background) {
            self.loadSmartAlbums()
        }
    }

    /// Load smart albums.
    fileprivate func loadSmartAlbums() {
        let library = PHPhotoLibrary.shared()
        library.unregisterChangeObserver(self)
        library.register(self)
        
        let fetch = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil)
        
        self.fetchResult = fetch
        
        if let albums = loadImages(from: fetch) {
            self.albums = albums
        }
    }

//    func loadAlbums() {
//        let albumOptions = PHFetchOptions()
//
//        albumOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
//        
//        let allAlbums = PHAssetCollection.fetchAssetCollectionsWithType(
//            .Album,
//            subtype: .Any,
//            options: albumOptions)
//    }
    
    /// Load images from a PHFetchResult.
    ///
    /// - Parameter fetch: The PHFetchResult to fetch images from.
    /// - Returns: An Array of Album instances.
    fileprivate func loadImages(from fetch: PHFetchResult<PHAssetCollection>)
        -> [Album]? {
        guard fetch.count > 0 else {
            return nil
        }
    
        var result = [Album]()
        let options = PHFetchOptions()
            
        options.predicate = NSPredicate(format: "mediaType = %i",
                                        PHAssetMediaType.image.rawValue)
            
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                    ascending: false)]

        fetch.enumerateObjects({
            let fetchResult = PHAsset.fetchAssets(in: $0.0, options: options)

            guard
                fetchResult.count > 0,
                let title = $0.0.localizedTitle,
                let assets = self.extractAsset(from: fetchResult)
            else {
                return
            }
            
            let album = Album.builder()
                .with(name: title)
                .add(assets: assets)
                .build()

            result.append(album)
        })

        return result
    }
    
    /// Extract all PHAsset from a PHFetchResult.
    ///
    /// - Parameter fetch: The PHFetchResult to pull assets from.
    /// - Returns: An Array of PHAsset.
    fileprivate func extractAsset(from fetch: PHFetchResult<PHAsset>)
        -> [PHAsset]?
    {
        guard fetch.count > 0 else {
            return nil
        }

        var result = [PHAsset]()
            
        fetch.enumerateObjects({
            result.append($0.0)
        })
            
        return result
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
