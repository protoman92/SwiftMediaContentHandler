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

/// This class can be used to get PHAsset of different types from 
/// PHPhotoLibrary.
public class LocalMediaDatabase: NSObject {
    
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
    fileprivate var photoLibraryObservable: Observable<Album>
    
    /// If this is set to true, empty Album instances will be filtered out
    /// from the final result.
    fileprivate var filterEmptyAlbums: Bool
    
    /// Return mediaTypes, a MediaType Array.
    public var registeredMediaTypes: [MediaType] {
        return mediaTypes
    }
    
    /// Return collectionTypes, a MediaCollectionType Array.
    public var registeredCollectionTypes: [MediaCollectionType] {
        return collectionTypes
    }
    
    /// Return photoLibraryListener
    var mediaListener: PublishSubject<PHAssetCollection> {
        return photoLibraryListener
    }
    
    /// Return photoLibraryObservable.
    public var mediaObservable: Observable<Album> {
        return photoLibraryObservable
    }
    
    /// Return filterEmptyAlbums.
    public var shouldFilterEmptyAlbums: Bool {
        return filterEmptyAlbums
    }
    
    override init() {
        assetCollectionFetch = []
        collectionTypes = []
        filterEmptyAlbums = true
        mediaTypes = []
        photoLibraryListener = PublishSubject<PHAssetCollection>()
        
        // Placebo value - we will immediately update it after self has been
        // initialized successfully.
        photoLibraryObservable = Observable.empty()
        super.init()
        photoLibraryObservable = rxLoadAlbums()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    /// Check for PHPhotoLibrary permission, and then load albums reactively
    /// if authorized.
    ///
    /// - Returns: An Observable instance.
    public func rxLoadAlbums() -> Observable<Album> {
        return mediaListener
            .flatMap({(collection) -> Observable<Album> in
                if self.isAuthorized() {
                    return self.rxLoadAlbums(collection: collection)
                } else {
                    let error = MediaError.permissionNotGranted
                    return Observable.error(error)
                }
            })
            // If filterEmptyAlbums is true, filter out empty Albums.
            .filter({!self.shouldFilterEmptyAlbums || $0.isNotEmpty})
            .applyCommonSchedulers()
    }
    
    /// Load Album reactively, using a PHAssetCollection and PHFetchOptions.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to get PHAsset instances.
    ///   - options: The PHFetchOptions to use for the fetching.
    /// - Returns: An Observable instance.
    func rxLoadAlbums(collection: PHAssetCollection) -> Observable<Album> {
        let fetchOptions = registeredMediaTypes.map(self.fetchOptions)
        
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
    func rxLoadAlbums(collection: PHAssetCollection, options: PHFetchOptions)
        -> Observable<Album>
    {
        let result = PHAsset.fetchAssets(in: collection, options: options)
        
        return Observable<PHAsset>
            .create({observer in
                self.observeFetchResult(result, with: observer)
                return Disposables.create()
            })
            .toArray()
            .map({self.createAlbum(with: collection, with: $0)})
    }
    
    /// Observe PHAsset from a PHFetchResult, using an Observer. This method
    /// is used in rxLoadAlbums(collection:, options:), so that we can
    /// override it during testing to return test Album instances.
    ///
    /// - Parameters:
    ///   - result: A PHFetchResult instance.
    ///   - observer: An AnyObserver instance.
    func observeFetchResult(_ result: PHFetchResult<PHAsset>,
                            with observer: AnyObserver<PHAsset>) {
        let count = result.count
        
        if count > 0 {
            result.enumerateObjects({
                observer.onNext($0.0)
                
                if $0.1 == count - 1 {
                    observer.onCompleted()
                }
            })
        } else {
            observer.onCompleted()
        }
    }
    
    /// Create an Album instance.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to which the Album belongs.
    ///   - assets: An Array of PHAsset instances.
    /// - Returns: An Album instance.
    func createAlbum(with collection: PHAssetCollection,
                     with assets: [PHAsset]) -> Album {
        return Album.builder()
            /// If the album does not have a title, leave empty and
            /// delegate to caller.
            .with(name: collection.localizedTitle ?? defaultAlbumName())
            .add(assets: assets)
            .build()
    }
    
    /// Get the default Album name that will be used when a PHAssetCollection
    /// has no title.
    ///
    /// - Returns: A String value.
    func defaultAlbumName() -> String {
        return "media.title.untitled".localized
    }
    
    public class Builder {
        fileprivate let database: LocalMediaDatabase
        
        fileprivate init() {
            database = LocalMediaDatabase()
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
        
        public func build() -> LocalMediaDatabase {
            return database
        }
    }
}

public extension LocalMediaDatabase {
    public static func builder() -> Builder {
        return Builder()
    }
}

public extension LocalMediaDatabase {
    
    /// Get the current authorization status for PHPhotoLibrary.
    public var currentAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    
    /// Check if the user has granted Photos permission. This method can be
    /// used in conjunction with Observable.filter.
    ///
    /// - Returns: A Bool value.
    public func isAuthorized() -> Bool {
        return currentAuthorizationStatus == .authorized
    }
}

public extension LocalMediaDatabase {
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
}

public extension LocalMediaDatabase {
    
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
        loadInitialAlbums(status: currentAuthorizationStatus)
    }
    
    /// Reload albums after checking authorization status.
    ///
    /// - Parameter status: PHPhotoLibrary authorization status.
    fileprivate func loadInitialAlbums(status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            registerChangeObserver()
            
            let mediaListener = self.mediaListener
            
            // Initialize the PHFetchResult Array here, instead of when the
            // instance is first built. This is because doing this will
            // explicitly request permission - we only want to ask for
            // permission when the app first starts loading Albums.
            assetCollectionFetch = registeredCollectionTypes.map({
                PHAssetCollection.fetchAssetCollections(
                    with: $0.collectionType,
                    subtype: .any,
                    options: nil)
            })
            
            assetCollectionFetch.forEach({
                $0.enumerateObjects({mediaListener.onNext($0.0)})
            })
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(loadInitialAlbums)
            
        default:
            break
        }
    }
}

extension LocalMediaDatabase: PHPhotoLibraryChangeObserver {
    
    /// When media content is added or deleted, call this method.
    ///
    /// - Parameter changeInstance: A PHChange instance.
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        let mediaListener = self.mediaListener
        
        assetCollectionFetch
            .flatMap(changeInstance.changeDetails)
            .map({$0.changedObjects})
            .reduce([], +)
            .forEach(mediaListener.onNext)
    }
}
