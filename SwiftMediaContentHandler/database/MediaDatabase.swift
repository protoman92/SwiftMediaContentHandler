//
//  MediaDatabase.swift
//  SwiftMediaContentHandler
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
    public var allPhotos: [LocalMedia] {
        return allPhotos(from: albums)
    }
    
    /// We can use this mediaHandler instance to cache and load media.
    public var mediaHandler: MediaHandlerProtocol?
    
    /// We can add collection types to fetch with PHFetchRequest.
    fileprivate var collectionTypes: [MediaCollectionType]
    
    /// We can add media types to fetch with PHFetchRequest.
    fileprivate var mediaTypes: [MediaType]
    
    /// For each collection type, we should have a PHFetchResult instance.
    fileprivate var assetCollectionFetch: [PHFetchResult<PHAssetCollection>]
    
    /// The options to be used for the fetch operation.
    fileprivate let fetchOptions: PHFetchOptions
    
    /// When a Photo library change is detected, call onNext.
    fileprivate let photoLibraryListener: PublishSubject<PHAssetCollection>
    
    /// This Album array contains PHAsset instances that can be queried later
    /// using MediaHandler.
    fileprivate var albums = [Album]()
    
    fileprivate override init() {
        photoLibraryListener = PublishSubject<PHAssetCollection>()
        collectionTypes = []
        mediaTypes = []
        assetCollectionFetch = []
        fetchOptions = PHFetchOptions()
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    /// Call this method when Builder.build() is called.
    fileprivate func onInstanceBuilt() {
        // Initialize the PHFetchResult Array.
        assetCollectionFetch = collectionTypes.map({
            PHAssetCollection.fetchAssetCollections(
                with: $0.collectionType,
                subtype: .any,
                options: nil)
        })
        
        // Initialize the fetch options.
        let types = mediaTypes.map({$0.assetType.rawValue})
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", types)
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
    }
    
    /// Get all Photo instances from an albums Array.
    ///
    /// - Parameter albums: An Array of Album instances.
    /// - Returns: An Array of Photo instances.
    fileprivate func allPhotos(from albums: [Album]) -> [LocalMedia] {
        return albums.map({$0.medias}).reduce([LocalMedia](), +)
    }
    
    public class Builder {
        fileprivate let database: MediaDatabase
        
        fileprivate init() {
            database = MediaDatabase()
        }
        
        /// Set the database's mediaHandler instance.
        ///
        /// - Parameter mediaHandler: An mediaHandler instance.
        /// - Returns: The current Builder instance.
        public func with(mediaHandler: MediaHandlerProtocol) -> Builder {
            database.mediaHandler = mediaHandler
            return self
        }
        
        /// Add a new MediaType to the set of acceptable media types. If this
        /// type already exists, do nothing.
        ///
        /// - Parameter type: A MediaType instance.
        /// - Returns: The current Builder instance.
        public func add(mediaType type: MediaType) -> Builder {
            database.mediaTypes.append(uniqueElement: type)
            return self
        }
        
        /// Add a new MediaCollectionType to the set of acceptable collection types.
        /// If this type already exists, do nothing.
        ///
        /// - Parameter type: A MediaCollectionType instance.
        /// - Returns: The current Builder instance.
        public func add(collectionType type: MediaCollectionType) -> Builder {
            database.collectionTypes.append(uniqueElement: type)
            return self
        }
        
        public func build() -> MediaDatabase {
            database.onInstanceBuilt()
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
    
    /// Check PHPhotoLibrary authorization.
    ///
    /// - Returns: An Observable instance.
    public func rxAuthorize() -> Observable<Bool> {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            return Observable.just(true)
            
        case .notDetermined:
            return Observable<PHAuthorizationStatus>
                .create({observer in
                    PHPhotoLibrary.requestAuthorization() {
                        observer.onNext($0)
                    }
                    
                    return Disposables.create()
                })
                .filter({$0 == .authorized})
                .throwIfEmpty(MediaError.permissionNotGranted)
                .map({_ in true})
            
        default:
            return Observable.error(MediaError.permissionNotGranted)
        }
    }
}

public extension MediaDatabase {
    
    /// Register PHPhotoLibrary listener.
    fileprivate func setPhotoLibraryListener() {
        PHPhotoLibrary.shared().register(self)
    }
}

public extension MediaDatabase {
    
    /// Reload smart albums if the user has authorized access to 
    /// PHPhotoLibrary. This method should be called only once to load initial
    /// media data. Subsequently, changes should be handled by PHPhotoLibrary's
    /// listener method.
    public func loadInitialAlbums() {
        let photoLibraryListener = self.photoLibraryListener
        
        assetCollectionFetch.forEach({
            $0.enumerateObjects({
                photoLibraryListener.onNext($0.0)
            })
        })
    }
    
    /// Check for PHPhotoLibrary permission, and then load albums reactively
    /// if authorized.
    ///
    /// - Returns: An Observable instance.
    public func rxLoadAlbums() -> Observable<Album> {
        return photoLibraryListener
            .flatMap({collection in self.rxAuthorize()
                .flatMap({_ in
                    self.rxLoadAlbums(collection: collection)
                })
            })
    }
    
    /// Load Album reactively, using a PHAssetCollection and PHFetchOptions.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to get PHAsset instances.
    ///   - options: The PHFetchOptions to use for the fetching.
    /// - Returns: An Observable instance.
    fileprivate func rxLoadAlbums(collection: PHAssetCollection)
        -> Observable<Album>
    {
        return rxLoadAlbums(collection: collection, options: fetchOptions)
    }
    
    /// Load Album reactively, using a PHAssetCollection and PHFetchOptions.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to get PHAsset instances.
    ///   - options: The PHFetchOptions to use for the fetching.
    /// - Returns: An Observable instance.
    fileprivate func rxLoadAlbums(collection: PHAssetCollection,
                                  options: PHFetchOptions)
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
        let photoLibraryListener = self.photoLibraryListener
        
        assetCollectionFetch
            .flatMap(changeInstance.changeDetails)
            .map({$0.changedObjects})
            .reduce([], +)
            .forEach(photoLibraryListener.onNext)
    }
}
