//
//  MediaDatabase.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/9/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import Foundation
import Photos
import RxSwift
import SwiftUtilities

/// This class can be used to get PHAsset of different types from PHPhotoLibrary.
/// To use it, we first need to register observers for mediaListener, after
/// which new media content will be delivered once available. Afterwards, we
/// must call loadInitialMedia() once to ask for user permission and set up
/// the internals. Once the user has granted permission, this class can do its
/// work - otherwise, its mediaListener will emit errors.
public class LocalMediaDatabase: NSObject {
    
    /// We can add collection types to fetch with PHFetchRequest.
    fileprivate var collectionTypes: [MediaCollectionType]
    
    /// This is responsible for providing error messages.
    fileprivate var errorProvider: MediaDatabaseErrorType
    
    /// We can add media types to fetch with PHFetchRequest.
    fileprivate var mediaTypes: [MediaType]
    
    /// Use this SortDescriptor to sort PHAsset while fetching.
    fileprivate var sortDescriptor: SortDescriptor<PHAsset>
    
    /// For each collection type, we should have a PHFetchResult instance.
    fileprivate var assetCollectionFetch: [PHFetchResult<PHAssetCollection>]
    
    /// When a Photo library change is detected, call onNext.
    fileprivate let photoLibraryListener: PublishSubject<PHAssetCollection>
    
    /// When there is a database-wide Error. i.e. errors that affect the entire
    /// fetch operation - such as permission error, call onNext.
    /// When the error is resolved, pass in an empty Optional.
    fileprivate let databaseErrorListener: PublishSubject<Optional<Error>>
    
    /// When this Observable is subscribed to, it will emit data that it
    /// fetches from PHPhotoLibrary.
    fileprivate var photoLibraryObservable: Observable<AlbumResult>
    
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
    
    /// Return databaseErrorListener
    public var databaseErrorObservable: Observable<Optional<Error>> {
        return databaseErrorListener.asObservable()
    }
    
    /// Return photoLibraryObservable.
    public var mediaObservable: Observable<AlbumResult> {
        return photoLibraryObservable
    }
    
    override init() {
        assetCollectionFetch = []
        collectionTypes = []
        mediaTypes = []
        photoLibraryListener = PublishSubject<PHAssetCollection>()
        databaseErrorListener = PublishSubject<Optional<Error>>()
        sortDescriptor = .ascending(for: MediaSortMode.creationDate)
        errorProvider = DefaultMediaError()
        
        // Placebo value - we will immediately update it after self has been
        // initialized successfully.
        photoLibraryObservable = Observable.empty()
        super.init()
        photoLibraryObservable = rxa_loadMedia()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        debugPrint("Deinitialized \(self)")
    }
    
    /// Check for PHPhotoLibrary permission, and then load AlbumResult reactively
    /// if authorized.
    ///
    /// - Returns: An Observable instance.
    public func rxa_loadMedia() -> Observable<AlbumResult> {
        return mediaListener
            .concatMap({[weak self] (collection) -> Observable<AlbumResult> in
                if let `self` = self {
                    return `self`.rxa_loadMedia(from: collection)
                } else {
                    return Observable.empty()
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    /// Load AlbumResult reactively, using a PHAssetCollection.
    ///
    /// - Parameter collection: The PHAssetCollection to get PHAsset instances.
    /// - Returns: An Observable instance.
    func rxa_loadMedia(from collection: PHAssetCollection) -> Observable<AlbumResult> {
        if !isAuthorized() { return Observable.empty() }
        let fetchOptions = registeredMediaTypes.map(self.fetchOptions)
        
        // For each registered MediaType, we provide a separate PHFetchOptions.
        return Observable.from(fetchOptions)
            .concatMap({[weak self] (ops) -> Observable<AlbumResult> in
                if let `self` = self {
                    return `self`.rxa_loadMedia(from: collection, with: ops)
                } else {
                    return Observable.empty()
                }
            })
    }
    
    /// Load AlbumResult reactively, using a PHAssetCollection and PHFetchOptions.
    ///
    /// - Parameters:
    ///   - collection: The PHAssetCollection to get PHAsset instances.
    ///   - options: The PHFetchOptions to use for the fetching.
    /// - Returns: An Observable instance.
    func rxa_loadMedia(from collection: PHAssetCollection,
                       with options: PHFetchOptions)
        -> Observable<AlbumResult>
    {
        let result = PHAsset.fetchAssets(in: collection, options: options)
        let title = collection.localizedTitle ?? defaultAlbumName()
        
        return Observable<PHAsset>
            .create({[weak self] observer in
                self?.observeFetchResult(result, with: observer)
                return Disposables.create()
            })
            .map({[weak self] in
                self?.createMedia(with: $0, with: title) ?? .blank()
            })
            .filter({$0.hasLocalAsset()})
            .map(LMTResult.init).toArray()
            .map({[weak self] in
                self?.createAlbum(from: $0, with: title) ?? .empty()
            })
            .ofType(AlbumType.self)
            .map(AlbumResult.init)
            .catchErrorJustReturn({
                let message = $0.localizedDescription
                return AlbumResult(error: MediaError(message))
            })
            .subscribeOn(qos: .background)
    }
    
    /// Observe PHAsset from a PHFetchResult, using an Observer. This method
    /// is used in rxa_loadMedia(collection:, options:), so that we can
    /// override it during testing to return test LocalMedia instances.
    ///
    /// - Parameters:
    ///   - result: A PHFetchResult instance.
    ///   - observer: An AnyObserver instance.
    func observeFetchResult(_ result: PHFetchResult<PHAsset>,
                            with observer: AnyObserver<PHAsset>) {
        defer { observer.onCompleted() }
        result.enumerateObjects({observer.onNext($0.0)})
    }
    
    /// Get the default Album name that will be used when a PHAssetCollection
    /// has no title.
    ///
    /// - Returns: A String value.
    func defaultAlbumName() -> String {
        return "media.title.untitled".localized
    }
    
    /// Create a LocalMedia instance with PHAsset and album name.
    ///
    /// - Parameters:
    ///   - asset: A PHAsset instance.
    ///   - title: A String value.
    /// - Returns: A LocalMedia instance.
    func createMedia(with asset: PHAsset, with title: String) -> LocalMedia {
        return LocalMedia.builder()
            .with(asset: asset)
            .with(albumName: title)
            .build()
    }
    
    /// Create an Album instance with LMTResult and album name.
    ///
    /// - Parameters:
    ///   - medias: An Array of LMTResult.
    ///   - title: A String value.
    /// - Returns: An Album instance.
    func createAlbum(from medias: [LMTResult], with title: String) -> Album {
        return Album.builder().add(medias: medias).with(name: title).build()
    }
    
    /// Builder class for LocalMediaDatabase.
    public final class Builder {
        private let database: LocalMediaDatabase
        
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
        public func add(collectionTypes types: MediaCollectionType...) -> Builder {
            types.forEach({self.add(collectionType: $0)})
            return self
        }
        
        /// Set the sortDescriptor instance.
        ///
        /// - Parameter sortDescriptor: A SortDescriptor instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(sortDescriptor: SortDescriptor<PHAsset>) -> Builder {
            database.sortDescriptor = sortDescriptor
            return self
        }
        
        /// Set the errorProvider instance.
        ///
        /// - Parameter errorProvider: A MediaDatabaseErrorType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(errorProvider: MediaDatabaseErrorType) -> Builder {
            database.errorProvider = errorProvider
            return self
        }
        
        /// Get the LocalMediaDatabase instance.
        ///
        /// - Returns: A LocalMediaDatabase instance.
        public func build() -> LocalMediaDatabase {
            return database
        }
    }
}

public extension LocalMediaDatabase {
    
    /// Get a Builder instance.
    ///
    /// - Returns: A Builder instance.
    public static func builder() -> Builder {
        return Builder()
    }
}

fileprivate extension LocalMediaDatabase {
    
    /// Convenient method to start fetch for a new PHAssetCollection.
    ///
    /// - Parameters:
    ///   - collection: A PHAssetCollection instance.
    ///   - observer: An Observer instance.
    fileprivate func startFetch<O: ObserverType>(
        for collection: PHAssetCollection,
        with observer: O
    ) where O.E == PHAssetCollection {
        observer.onNext(collection)
    }
    
    /// Convenient to start fetch with a lock.
    ///
    /// - Parameter collection: A PHAssetCollection instance.
    fileprivate func startFetch(for collection: PHAssetCollection) {
        let mediaListener = self.mediaListener
        
        synchronized(mediaListener, then: {
            self.startFetch(for: collection, with: mediaListener)
        })
    }
    
    /// Start fetch for all PHFetchResult.
    fileprivate func startFetch() {
        assetCollectionFetch.forEach({
            $0.enumerateObjects({self.startFetch(for: $0.0)})
        })
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

fileprivate extension LocalMediaDatabase {
    
    /// Create a PHFetchOptions based on a MediaType instance.
    ///
    /// - Parameter type: A MediaType instance.
    /// - Returns: A PHFetchOptions instance.
    fileprivate func fetchOptions(for type: MediaType) -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        let typeValue = type.assetType.rawValue
        let predicate = NSPredicate(format: "mediaType = %i", typeValue)
        fetchOptions.predicate = predicate
        fetchOptions.sortDescriptors = [sortDescriptor.descriptor()]
        return fetchOptions
    }
}

public extension LocalMediaDatabase {
    
    /// Register PHPhotoLibraryChangeObserver.
    fileprivate func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    /// Reload AlbumResult if the user has authorized access to PHPhotoLibrary.
    ///
    /// This method should be called only once to load initial media data. 
    /// Subsequently, changes should be handled by PHPhotoLibrary's listener 
    /// method.
    ///
    /// We first need to check for PHPhotoLibrary authorization.
    public func loadInitialMedia() {
        loadInitialMedia(status: currentAuthorizationStatus)
    }
    
    /// Reload AlbumResult after checking authorization status.
    ///
    /// - Parameter status: PHPhotoLibrary authorization status.
    fileprivate func loadInitialMedia(status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            // Emit an empty Optional to indicate that the Error has been
            // resolved.
            databaseErrorListener.onNext(Optional.none)
            
            registerChangeObserver()
            
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
            
            startFetch()
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(loadInitialMedia)
            
        default:
            let error = Exception(errorProvider.permissionNotGranted)
            databaseErrorListener.onNext(error)
        }
    }
}

extension LocalMediaDatabase: PHPhotoLibraryChangeObserver {
    
    /// When media content is added or deleted, call this method.
    ///
    /// - Parameter changeInstance: A PHChange instance.
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        assetCollectionFetch
            .flatMap(changeInstance.changeDetails)
            .map({$0.changedObjects})
            .reduce([], +)
            .forEach(startFetch)
    }
}
