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
    /// We can use this mediaHandler instance to cache and load media.
    fileprivate var handler: MediaHandlerProtocol?
    
    /// We can add collection types to fetch with PHFetchRequest.
    fileprivate var collectionTypes: [MediaCollectionType]
    
    /// We can add media types to fetch with PHFetchRequest.
    fileprivate var mediaTypes: [MediaType]
    
    /// For each collection type, we should have a PHFetchResult instance.
    fileprivate var assetCollectionFetch: [PHFetchResult<PHAssetCollection>]
    
    /// When a Photo library change is detected, call onNext.
    fileprivate let photoLibraryListener: PublishSubject<PHAssetCollection>
    
    /// When this Observable is subscribed to, it will emit data that it
    /// fetches from PHPhotoLibrary.
    fileprivate var photoLibraryObservable: Observable<Album>?
    
    /// If this is set to true, empty Album instances will be filtered out
    /// from the final result.
    fileprivate var filterEmptyAlbums: Bool
    
    public var mediaHandler: MediaHandlerProtocol? {
        return handler
    }
    
    public var mediaObservable: Observable<Album>? {
        return photoLibraryObservable
    }
    
    fileprivate override init() {
        assetCollectionFetch = []
        collectionTypes = []
        filterEmptyAlbums = true
        mediaTypes = []
        photoLibraryListener = PublishSubject<PHAssetCollection>()
        super.init()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
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
        @discardableResult
        public func with(mediaHandler: MediaHandlerProtocol) -> Builder {
            database.handler = mediaHandler
            return self
        }
        
        /// Add a new MediaType to the set of acceptable media types. If this
        /// type already exists, do nothing.
        ///
        /// - Parameter type: A MediaType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(mediaType type: MediaType) -> Builder {
            database.mediaTypes.append(uniqueElement: type)
            return self
        }
        
        /// Add new MediaType instances to the set of acceptable media types.
        ///
        /// - Parameter types: A vararg MediaType Array.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(mediaTypes types: MediaType...) -> Builder {
            types.forEach({self.add(mediaType: $0)})
            return self
        }
        
        /// Add a new MediaCollectionType to the set of acceptable collection 
        /// types. If this type already exists, do nothing.
        ///
        /// - Parameter type: A MediaCollectionType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(collectionType type: MediaCollectionType) -> Builder {
            database.collectionTypes.append(uniqueElement: type)
            return self
        }
        
        /// Add new MediaCollectionType instances to the set of acceptable
        /// collection types.
        ///
        /// - Parameter types: A vararg MediaCollectionType Array.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(collectionTypes types: MediaCollectionType...)
            -> Builder
        {
            types.forEach({self.add(collectionType: $0)})
            return self
        }
        
        /// Set the database's filterEmptyAlbums value.
        ///
        /// - Parameter filter: A Bool value.
        /// - Returns: The current Builder instance.
        public func filterEmptyAlbums(_ filter: Bool) -> Builder {
            database.filterEmptyAlbums = filter
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
    /// Call this method when Builder.build() is called.
    fileprivate func onInstanceBuilt() {
        // Initialize the PHPhotoLibrary Observable.
        photoLibraryObservable = rxLoadAlbums()
    }
}

public extension MediaDatabase {
    
    /// Check if the user has granted Photos permission. This method can be
    /// used in conjunction with Observable.filter.
    ///
    /// - Returns: A Bool value.
    public func isAuthorized() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
}

public extension MediaDatabase {
    
    /// Register PHPhotoLibraryChangeObserver.
    fileprivate func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    /// Reload albums if the user has authorized access to PHPhotoLibrary.
    ///
    /// This method should be called only once to load initial
    /// media data. Subsequently, changes should be handled by PHPhotoLibrary's
    /// listener method.
    ///
    /// We first need to check for PHPhotoLibrary authorization.
    public func loadInitialAlbums() {
        let status = PHPhotoLibrary.authorizationStatus()
        loadInitialAlbums(status: status)
    }
    
    /// Reload albums after checking authorization status.
    ///
    /// - Parameter status: PHPhotoLibrary authorization status.
    fileprivate func loadInitialAlbums(status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            registerChangeObserver()
            
            let photoLibraryListener = self.photoLibraryListener
            
            // Initialize the PHFetchResult Array here, instead of when the
            // instance is first built. This is because doing this will
            // explicitly request permission - we only want to ask for
            // permission when the app first starts loading Albums.
            assetCollectionFetch = collectionTypes.map({
                PHAssetCollection.fetchAssetCollections(
                    with: $0.collectionType,
                    subtype: .any,
                    options: nil)
            })
            
            assetCollectionFetch.forEach({
                $0.enumerateObjects({
                    photoLibraryListener.onNext($0.0)
                })
            })
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(loadInitialAlbums)
            
        default:
            break
        }
    }
}

public extension MediaDatabase {
    
    /// Create a PHFetchOptions based on a MediaType instance.
    ///
    /// - Parameter type: A MediaType instance.
    /// - Returns: A PHFetchOptions instance.
    fileprivate func fetchOptions(for type: MediaType) -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        let typeValue = type.assetType.rawValue
        let predicate = NSPredicate(format: "mediaType = %i", typeValue)
        fetchOptions.predicate = predicate
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        return fetchOptions
    }

    /// Check for PHPhotoLibrary permission, and then load albums reactively
    /// if authorized.
    ///
    /// - Returns: An Observable instance.
    public func rxLoadAlbums() -> Observable<Album> {
        return photoLibraryListener
            .flatMap({(collection) -> Observable<Album> in
                if self.isAuthorized() {
                    return self.rxLoadAlbums(collection: collection)
                } else {
                    let error = MediaError.permissionNotGranted
                    return Observable<Album>.error(error)
                }
            })
            .applyCommonSchedulers()
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
        let fetchOptions = mediaTypes.map(self.fetchOptions)
        
        // For each registered MediaType, we provide a separate PHFetchOptions.
        return Observable
            .from(fetchOptions)
            .flatMap({self.rxLoadAlbums(collection: collection, options: $0)})
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
            .map({self.createAlbum(with: collection, with: $0)})
            
            // If filterEmptyAlbums is true, filter out empty Album.
            .filter({!self.filterEmptyAlbums || $0.isNotEmpty})
    }
    
    /// Create an Album instance.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to which the Album belongs.
    ///   - assets: An Array of PHAsset instances.
    /// - Returns: An Album instance.
    fileprivate func createAlbum(with collection: PHAssetCollection,
                                 with assets: [PHAsset]) -> Album {
        return Album.builder()
            /// If the album does not have a title, leave empty and
            /// delegate to caller.
            .with(name: collection.localizedTitle ?? "")
            .add(assets: assets)
            .build()
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
