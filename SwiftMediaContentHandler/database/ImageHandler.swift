//
//  BaseImageDownloaded.swift
//  Heartland Chefs
//
//  Created by Hai Pham on 8/6/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import Photos
import SDWebImage
import RxSwift
import SwiftUtilities
import UIKit

public protocol ImageHandlerProtocol {
    
    /// Load an image based on an ImageHandler.Request.
    ///
    /// - Parameter request: An ImageHandler.Request instance.
    func request(with request: ImageHandler.Request)
    
    /// Load an image reactively, based on an ImageHandler.Request.
    ///
    /// - Parameter request: An ImageHandler.Request instance.
    /// - Returns: An Observable instance.
    func rxRequest(with request: ImageHandler.Request) -> Observable<UIImage>
    
    /// Cache an Array of Photo instances, using a targetSize.
    ///
    /// - Parameters:
    ///   - assets: An Array of Photo to be cached.
    ///   - size: The size used to cache the images.
    func cache(assets: [Photo], targetSize size: CGSize)
    
    /// Stop caching images.
    func stopAssetCache()
    
    
    /// Check permission to access Photos SDK.
    ///
    /// - Parameters:
    ///   - status: The current authorization status.
    ///   - completion: Completion closure.
    func checkAuthorization(status: PHAuthorizationStatus,
                            completion: ((Bool) -> Void)?)
}

public protocol WebImageHandlerProtocol {
    
    /// Load an image based on an ImageHandler.WebRequest
    ///
    /// - Parameter request: An ImageHandler.WebRequest instance.
    func requestRemotely(with request: ImageHandler.WebRequest)
}

public protocol LocalImageHandlerProtocol {
    
    /// Load an image based on an ImageHandler.LocalRequest.
    ///
    /// - Parameter request: An ImageHandler.LocalRequest instance.
    func requestLocally(with request: ImageHandler.LocalRequest)
}

public typealias ImageCallback = (UIImage?, Error?) -> Void

public class ImageHandler: NSObject {
    fileprivate let fastOptions: PHImageRequestOptions
    fileprivate var phManager: PHImageManager?
    fileprivate let manager: SDWebImageManager? = SDWebImageManager.shared()
    
    fileprivate var capacity: UInt64? {
        get {
            guard let capacity = manager?.imageCache?.config.maxCacheSize else {
                return nil
            }
            
            return UInt64(capacity)
        }
        
        set {
            guard let capacity = newValue else {
                return
            }
            
            manager?.imageCache?.config.maxCacheSize = UInt(capacity)
        }
    }
    
    public override init() {
        fastOptions = PHImageRequestOptions()
        super.init()
        fastOptions.isSynchronous = false
        fastOptions.deliveryMode = .fastFormat
        fastOptions.resizeMode = .fast
        
        // We can change the capacity using ImageHandler.Builder
        capacity = UInt64(100 * 1024 * 1024)
    }

    /// Get a cached UIImage using an identifier.
    ///
    /// - Parameter identifier: The UIImage's identifier.
    /// - Returns: An optional UIImage.
    public func cachedImage(withIdentifier identifier: String) -> UIImage? {
        return manager?.imageCache?.imageFromMemoryCache(forKey: identifier)
    }

    /// Cache an UIImage using an identifier.
    ///
    /// - Parameters:
    ///   - image: The UIImage to be cached.
    ///   - id: The UIImage's identifier.
    public func cache(image: UIImage, withId id: String) {
        manager?.imageCache?.store(image, forKey: id)
    }
    
    /// Cache an Array of Photo.
    ///
    /// - Parameters:
    ///   - assets: The Array of Photo to be cached.
    ///   - size: The Photos' target size.
    public func cache(assets: [Photo], targetSize size: CGSize) {}

    /// Clear the UIImage cache.
    public func clearCache() {
        manager?.imageCache?.clearMemory()
    }
    
    /// Stop caching UIimage objects.
    public func stopAssetCache() {}
    
    public class Builder {
        fileprivate let handler: ImageHandler
        
        fileprivate init() {
            handler = ImageHandler()
        }
        
        /// Set the handler's cache capacity.
        ///
        /// - Parameter capacity: A UInt64 value.
        /// - Returns: The current Builder instance.
        public func with(capacity: UInt64) -> Builder {
            handler.capacity = capacity
            return self
        }
        
        public func build() -> ImageHandler {
            return handler
        }
    }
    
    public class Request: NSObject {
        
        /// This closure will be called when an image is fetched, or an Error
        /// is thrown.
        fileprivate var completion: ((UIImage?, Error?) -> Void)?
        
        /// Return a new BaseBuilder instance. This is useful for when we
        /// want to clone a Request instance.
        ///
        /// - Returns: A BaseBuilder instance.
        fileprivate func builder() -> BaseBuilder {
            fatalError()
        }
        
        public class BaseBuilder {
            fileprivate let request: Request
            
            fileprivate init(request: Request) {
                self.request = request
            }
            
            /// Set the completion closure.
            ///
            /// - Parameter completion: The completion closure.
            /// - Returns: The current Builder instance.
            @discardableResult
            public func with(completion: @escaping (UIImage?, Error?) -> Void)
                -> BaseBuilder {
                request.completion = completion
                return self
            }
            
            /// Copy properties from another Request.
            ///
            /// - Parameter request: A Request instance.
            /// - Returns: The current Builder instance.
            @discardableResult
            public func with(request: Request) -> BaseBuilder {
                if let completion = request.completion {
                    with(completion: completion)
                }
                
                return self
            }
            
            public func build() -> Request {
                return request
            }
        }
    }
    
    /// Download image remotely.
    public class WebRequest: Request {
        /// If this variable is set: web image download.
        fileprivate var url: String?
        
        override
        fileprivate func builder() -> ImageHandler.Request.BaseBuilder {
            return ImageHandler.webRequestBuilder()
        }
        
        public class Builder: Request.BaseBuilder {
            fileprivate var webRequest: WebRequest? {
                return request as? WebRequest
            }
            
            fileprivate init() {
                super.init(request: WebRequest())
            }
            
            /// Copy properties from another WebRequest.
            ///
            /// - Parameter request: A WebRequest instance.
            /// - Returns: The current Builder instance.
            @discardableResult
            override
            public func with(request: ImageHandler.Request) -> Builder {
                if let request = request as? WebRequest {
                    if let url = request.url {
                        with(url: url)
                    }
                }
                    
                return self
            }
            
            /// Set the url variable for request.
            ///
            /// - Parameter url: A String value.
            /// - Returns: The current Builder instance.
            @discardableResult
            public func with(url: String) -> Builder {
                webRequest?.url = url
                return self
            }
        }
    }
    
    /// Download image locally.
    public class LocalRequest: Request {
        public enum Mode {
            case normal(size: CGSize)
            case full
            
            /// If we are requesting a full image, this is not needed.
            fileprivate var size: CGSize? {
                switch self {
                case .normal(let size):
                    return size
                    
                default:
                    return nil
                }
            }
        }
        
        /// If this variable is set, local image load.
        fileprivate var photo: Photo?
        
        /// Specify if the image is to be resized, or kept at full size.
        fileprivate var mode: Mode
        
        override
        fileprivate func builder() -> ImageHandler.Request.BaseBuilder {
            return ImageHandler.localRequestBuilder()
        }
        
        fileprivate override init() {
            mode = .full
            super.init()
        }
        
        public class Builder: Request.BaseBuilder {
            fileprivate var localRequest: LocalRequest? {
                return request as? LocalRequest
            }
            
            fileprivate init() {
                super.init(request: LocalRequest())
            }
            
            /// Copy properties from another WebRequest.
            ///
            /// - Parameter request: A WebRequest instance.
            /// - Returns: The current Builder instance.
            @discardableResult
            override
            public func with(request: ImageHandler.Request) -> Builder {
                if let request = request as? LocalRequest {
                    if let photo = request.photo {
                        with(photo: photo)
                    }
                    
                    with(mode: request.mode)
                }
                
                return self
            }
            
            /// Set the photo variable for request.
            ///
            /// - Parameter photo: A Photo instance.
            /// - Returns: The current Builder instance.
            @discardableResult
            public func with(photo: Photo) -> Builder {
                localRequest?.photo = photo
                return self
            }
            
            /// Set the mode variable for request.
            ///
            /// - Parameter mode: A Mode instance.
            /// - Returns: The current Builder instance.
            @discardableResult
            public func with(mode: Mode) -> Builder {
                localRequest?.mode = mode
                return self
            }
        }

    }
}

public extension ImageHandler {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public static func webRequestBuilder() -> WebRequest.Builder {
        return WebRequest.Builder()
    }
    
    public static func localRequestBuilder() -> LocalRequest.Builder {
        return LocalRequest.Builder()
    }
}

public extension ImageHandler {
    
    /// Request an image, either remotely or locally, depending on the type
    /// of request.
    ///
    /// - Parameter request: A Request instance.
    public func request(with request: Request) {
        switch request {
        case let webRequest as WebRequest:
            self.request(with: webRequest)
            
        case let localRequest as LocalRequest:
            self.request(with: localRequest)
            
        default:
            debugException()
        }
    }
    
    /// Reactively request an image and emit an UIImage, or an Error.
    ///
    /// - Parameter request: A Request instance.
    /// - Returns: An Observable instance.
    public func rxRequest(with request: Request) -> Observable<UIImage> {
        return Observable
            .create({(observer) in
                let completion: (UIImage?, Error?) -> Void = {
                    if let image = $0.0 {
                        observer.onNext(image)
                        observer.onCompleted()
                    } else if let error = $0.1 {
                        observer.onError(error)
                    } else {
                        observer.onCompleted()
                    }
                }
                
                self.request(with: request.builder()
                    .with(request: request)
                    .with(completion: completion)
                    .build())
                
                return Disposables.create()
            })
            .applyCommonSchedulers()
    }
}

// MARK: - Web image handling

public extension ImageHandler {
    
    /// Download an image remotely.
    ///
    /// - Parameter request: A WebRequest instance.
    public func requestRemotely(with request: WebRequest) {
        let completion = request.completion
        
        guard let url = request.url, let imageUrl = URL(string: url) else {
            debugException()
            
            mainThread {
                completion?(nil, nil)
            }
            
            return
        }
        
        _ = manager?.imageDownloader?.downloadImage(
            with: imageUrl,
            options: .highPriority,
            progress: nil)
        {
            let image = $0.0
            let error = $0.2
            
            mainThread {
                completion?(image, error)
            }
        }
    }
}

// MARK: - Local image handling

public extension ImageHandler {
    
    /// Check authorization status from PHPhotoLibrary.
    ///
    /// - Parameter completion: Completion closure.
    public func checkAuthorization(completion: ((Bool) -> Void)?) {
        checkAuthorization(status: PHPhotoLibrary.authorizationStatus(),
                           completion: completion)
    }
    
    /// Check authorization status from PHPhotoLibrary. If media access is
    /// granted, we can initialze the PHImageManager instances - this is done
    /// so as to avoid crashes that may occur upon PHImageManager 
    /// initialization if permission is not granted.
    ///
    /// This method should be called when the app is first started.
    ///
    /// - Parameters:
    ///   - status: The authorization status being checked.
    ///   - completion: Completion closure.
    public func checkAuthorization(status: PHAuthorizationStatus,
                                   completion: ((Bool) -> Void)?) {
        switch status {
        case .authorized:
            phManager = PHImageManager()
            
        case .denied, .restricted:
            phManager = nil
            
        default:
            break
        }
    }
}

public extension ImageHandler {
    
    /// Request an image locally. Depending on the request mode, this can
    /// either load a resized or a full image.
    ///
    /// - Parameter request: A LocalRequest instance.
    public func requestLocally(with request: LocalRequest) {
        switch request.mode {
        case .normal:
            requestResizedImage(with: request)
            
        case .full:
            requestFullImage(with: request)
        }
    }
    
    /// Request a resized image locally.
    ///
    /// - Parameter request: A LocalRequest instance.
    fileprivate func requestResizedImage(with request: LocalRequest) {
        let completion = request.completion
        
        guard
            let phManager = self.phManager,
            let asset = request.photo?.asset,
            let size = request.mode.size
        else {
            debugException()
            
            mainThread {
                completion?(nil, nil)
            }

            return
        }
        
        let resultHandler: (UIImage?, [AnyHashable : Any]?) -> Void = {
            let image = $0.0
            
            mainThread {
                completion?(image, nil)
            }
        }
        
        phManager.requestImage(for: asset,
                               targetSize: size,
                               contentMode: .aspectFill,
                               options: nil,
                               resultHandler: resultHandler)
    }
    
    /// Request a full-sized image locally.
    ///
    /// - Parameter request: A LocalRequest instance.
    fileprivate func requestFullImage(with request: LocalRequest) {
        let completion = request.completion
        
        guard
            let phManager = self.phManager,
            let asset = request.photo?.asset
        else {
            debugException()
            
            mainThread {
                completion?(nil, nil)
            }
            
            return
        }
        
        phManager.requestImageData(for: asset, options: nil) {
            guard let data = $0.0, let image = UIImage(data: data) else {
                mainThread {
                    completion?(nil, nil)
                }
                
                return
            }
            
            mainThread {
                completion?(image, nil)
            }
        }

    }
}

extension ImageHandler: ImageHandlerProtocol {}

extension ImageHandler: WebImageHandlerProtocol {}

extension ImageHandler: LocalImageHandlerProtocol {}
