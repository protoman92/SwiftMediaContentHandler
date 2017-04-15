//
//  MediaHandler
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 8/6/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import Photos
import SDWebImage
import RxSwift
import SwiftUtilities
import UIKit

/// Catch-all completion closure for media loading.
public typealias MediaCallback = (Any?, Error?) -> Void

/// Classes that implement this protocol must be able to handle different
/// types of MediaRequest.
public protocol MediaHandlerProtocol {
    /// Load media reactively using a MediaRequest.
    ///
    /// - Parameter request: A MediaRequest instance.
    /// - Returns: An Observable instance.
    func rxRequest(with request: MediaRequest) -> Observable<Any>
    
    /// Load image reactively using a MediaRequest.
    ///
    /// - Parameter request: A MediaRequest instance.
    /// - Returns: An Observable instance.
    func rxRequestImage(with request: MediaRequest) -> Observable<UIImage>
}

/// Use this class to load various types of media from different sources.
/// The request will be forwarded to the correct methods, depending on the
/// type of MediaRequest used.
public class MediaHandler: NSObject {
    fileprivate var phManager: PHImageManager?
    fileprivate let manager: SDWebImageManager
    
    /// The cache to be used for web images.
    fileprivate var capacity: UInt64? {
        get {
            guard let capacity = manager.imageCache?.config.maxCacheSize else {
                return nil
            }
            
            return UInt64(capacity)
        }
        
        set {
            guard let capacity = newValue else {
                return
            }
            
            manager.imageCache?.config.maxCacheSize = UInt(capacity)
        }
    }
    
    override init() {
        manager = SDWebImageManager.shared()
        super.init()
        
        // We can change the capacity using MediaHandler.Builder
        capacity = UInt64(100 * 1024 * 1024)
    }
    
    /// Reactively request media. Emit an Error if necessary.
    ///
    /// - Parameter request: A MediaRequest instance.
    /// - Returns: An Observable instance.
    public func rxRequest(with request: MediaRequest) -> Observable<Any> {
        let source: Observable<Any>
        
        switch request {
        case let request as WebRequest:
            source = rxRequestWebMedia(with: request)
            
        case let request as LocalRequest:
            source = rxRequestLocalMedia(with: request)
            
        default:
            source = Observable.error(MediaError.mediaHandlerUnknownRequest)
        }
        
        return source.applyCommonSchedulers()
    }
    
    /// Request a UIImage. Should be the same as the above method, but casts
    /// the result to UIImage at the end.
    ///
    /// - Parameter request: A MediaRequest instance.
    /// - Returns: An Observable instance.
    public func rxRequestImage(with request: MediaRequest)
        -> Observable<UIImage>
    {
        return rxRequest(with: request)
            .filter({$0 is UIImage})
            .throwIfEmpty(MediaError.notAnImage)
            .map({$0 as! UIImage})
    }
    
    /// Request media remotely with rx.
    ///
    /// - Parameter request: A WebRequest instance.
    /// - Returns: An Observable instance.
    public func rxRequestWebMedia(with request: WebRequest) -> Observable<Any> {
        return Observable.create({observer in
            self.requestWebMedia(with: request) {
                if let result = $0.0 {
                    observer.onNext(result)
                    observer.onCompleted()
                } else if let error = $0.1 {
                    observer.onError(error)
                } else {
                    let error = Exception(MediaError.mediaUnavailable)
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        })
    }
    
    /// Request media remotely. This method delegates the work to other
    /// appropriate methods, depending on the request type.
    ///
    /// - Parameters:
    ///   - request: A WebRequest instance.
    ///   - complete: Completion closure.
    public func requestWebMedia(with request: WebRequest,
                                andThen complete: @escaping MediaCallback) {
        switch request {
        case let request as WebImageRequest:
            requestWebImage(with: request, andThen: complete)
            
        default:
            let message = MediaError.mediaHandlerUnknownRequest
            let error = Exception(message)
            mainThread {complete(nil, error)}
        }
    }
    
    /// Request a web image.
    ///
    /// - Parameters:
    ///   - request: A WebImageRequest instance.
    ///   - complete: Completion closure.
    public func requestWebImage(with request: WebImageRequest,
                                andThen complete: @escaping MediaCallback) {
        guard let url = request.url else {
            let error = Exception(MediaError.mediaUnavailable)
            mainThread {complete(nil, error)}
            return
        }
        
        _ = manager.imageDownloader?.downloadImage(
            with: url,
            options: .highPriority,
            progress: nil)
        {
            let image = $0.0
            let error = $0.2
            mainThread {complete(image, error)}
        }
    }
    
    /// Check if access to PHPhotoLibrary is authorized.
    ///
    /// - Returns: An Observable instance.
    public func rxIsAuthorized() -> Observable<Bool> {
        let status = PHPhotoLibrary.authorizationStatus()
        return Observable.just(status).map({$0 == .authorized})
    }
    
    /// Check authorization status from PHMediaLibrary. If media access is
    /// granted, we can initialze the PHImageManager instances - this is done
    /// so as to avoid crashes that may occur upon PHImageManager
    /// initialization if permission is not granted.
    ///
    /// If authorization is granted, initiaze the phManager if it has yet to
    /// be created.
    ///
    /// - Returns: An Observable instance.
    public func rxGetPHImageManager() -> Observable<PHImageManager> {
        
        /// If phManager has already been set, emit it immediately.
        if let phManager = self.phManager {
            return Observable.just(phManager)
        }
        
        return rxIsAuthorized()
            .flatMap(rxGetPHImageManager)
            .doOnNext(setPHImageManager)
    }
    
    /// When permission is granted, we initialize phManager or throw an Error
    /// otherwise.
    ///
    /// - Parameter granted: A Bool value.
    ///
    /// - Returns: An Observable instance.
    fileprivate func rxGetPHImageManager(permissionGranted granted: Bool)
        -> Observable<PHImageManager>
    {
        guard granted else {
            return Observable.error(MediaError.permissionNotGranted)
        }
        
        let phManager = PHImageManager()
        return Observable.just(phManager)
    }
    
    /// Set the PHImageManager instance.
    ///
    /// - Parameter manager: A PHImageManager instance.
    fileprivate func setPHImageManager(_ manager: PHImageManager) {
        if self.phManager == nil {
            self.phManager = manager
        }
    }
    
    /// Request media locally with rx.
    ///
    /// - Parameter request: A LocalRequest instance.
    /// - Returns: An Observable instance.
    public func rxRequestLocalMedia(with request: LocalRequest)
        -> Observable<Any>
    {
        return rxGetPHImageManager()
            .flatMap({manager in
                Observable<Any>.create({observer in
                    self.requestLocalMedia(with: request, using: manager) {
                        if let result = $0.0 {
                            observer.onNext(result)
                            observer.onCompleted()
                        } else if let error = $0.1 {
                            observer.onError(error)
                        } else {
                            // This error should not be expected. This means
                            // all handlers failed to return any response.
                            let error = Exception(MediaError.mediaUnavailable)
                            observer.onError(error)
                        }
                    }
                    
                    return Disposables.create()
                })
            })
    }
    
    /// Request media locally. This method delegates the work to other
    /// appropriate methods, depending on the request type.
    ///
    /// - Parameters:
    ///   - request: A LocalRequest instance.
    ///   - manager: A PHImageManager instance.
    ///   - complete: Completion closure.
    public func requestLocalMedia(with request: LocalRequest,
                                  using manager: PHImageManager,
                                  andThen complete: @escaping MediaCallback) {
        switch request {
        case let request as LocalImageRequest:
            requestLocalImage(with: request, using: manager, andThen: complete)
            
        default:
            let message = MediaError.mediaHandlerUnknownRequest
            let error = Exception(message)
            mainThread {complete(nil, error)}
        }
    }
    
    /// Request an image locally.
    ///
    /// - Parameters:
    ///   - request: A LocalImageRequest instance.
    ///   - manager: A PHImageManager instance.
    ///   - complete: Completion closure.
    public func requestLocalImage(with request: LocalImageRequest,
                                  using manager: PHImageManager,
                                  andThen complete: @escaping MediaCallback) {
        guard let asset = request.mediaAsset?.asset else {
            let error = Exception(MediaError.mediaUnavailable)
            mainThread {complete(nil, error)}
            return
        }
        
        /// If a size is specified, resize the image.
        if let size = request.imageSize {
            manager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: nil
            ) {
                let image = $0.0
                mainThread {complete(image, nil)}
            }
        } else {
            // We are requesting raw data from the local database, and then
            // converting it to an UIImage.
            manager.requestImageData(for: asset, options: nil) {
                guard let data = $0.0, let image = UIImage(data: data) else {
                    mainThread {complete(nil, nil)}
                    return
                }
                
                mainThread {complete(image, nil)}
            }
        }
    }
    
    public class Builder {
        fileprivate let handler: MediaHandler
        
        fileprivate init() {
            handler = MediaHandler()
        }
        
        /// Set the handler's cache capacity.
        ///
        /// - Parameter capacity: A UInt64 value.
        /// - Returns: The current Builder instance.
        public func with(capacity: UInt64) -> Builder {
            handler.capacity = capacity
            return self
        }
        
        public func build() -> MediaHandler {
            return handler
        }
    }
}

public extension MediaHandler {
    public static func builder() -> Builder {
        return Builder()
    }
}

extension MediaHandler: MediaHandlerProtocol {}
