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

public typealias MediaCallback = (Any?, Error?) -> Void

public protocol MediaHandlerProtocol {
    /// Load media reactively using a MediaRequest.
    ///
    /// - Parameter request: An MediaRequest instance.
    /// - Returns: An Observable instance.
    func rxRequest(with request: MediaRequest) -> Observable<Any>
    
    /// Check permission to access Medias SDK.
    ///
    /// - Parameters:
    ///   - status: The current authorization status.
    ///   - completion: Completion closure.
    func checkAuthorization(status: PHAuthorizationStatus,
                            completion: ((Bool) -> Void)?)
}

public class MediaHandler: NSObject {
    fileprivate var phManager: PHImageManager?
    fileprivate let manager: SDWebImageManager
    
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
    /// - Parameter request: A Request instance.
    /// - Returns: An Observable instance.
    public func rxRequest(with request: MediaRequest) -> Observable<Any> {
        return Observable
            .create({(observer) in
                self.requestMedia(with: request) {
                    if let media = $0.0 {
                        observer.onNext(media)
                        observer.onCompleted()
                    } else if let error = $0.1 {
                        observer.onError(error)
                    } else {
                        observer.onCompleted()
                    }
                }
                
                return Disposables.create()
            })
            .applyCommonSchedulers()
    }
    
    /// Request media, either remotely or locally.
    ///
    /// - Parameter request: A Request instance.
    public func requestMedia(with request: MediaRequest,
                             andThen complete: @escaping MediaCallback) {
        switch request {
        case let request as WebRequest:
            requestWebMedia(with: request, andThen: complete)
            
        case let request as LocalRequest:
            requestLocalMedia(with: request, andThen: complete)
            
        default:
            debugException()
            break
        }
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
            debugException()
            break
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
            debugException()
            complete(nil, nil)
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
    
    /// Request media locally. This method delegates the work to other
    /// appropriate methods, depending on the request type.
    ///
    /// - Parameters:
    ///   - request: A LocalRequest instance.
    ///   - complete: Completion closure.
    public func requestLocalMedia(with request: LocalRequest,
                                  andThen complete: @escaping MediaCallback) {
        switch request {
        case let request as LocalImageRequest:
            requestLocalImage(with: request, andThen: complete)
            
        default:
            debugException()
            break
        }
    }
    
    /// Request an image locally.
    ///
    /// - Parameters:
    ///   - request: A LocalImageRequest instance.
    ///   - complete: Completion closure.
    public func requestLocalImage(with request: LocalImageRequest,
                                  andThen complete: @escaping MediaCallback) {
        guard
            let phManager = self.phManager,
            let asset = request.mediaAsset?.asset
        else {
            debugException()
            mainThread {complete(nil, nil)}
            return
        }
        
        /// If a size is specified, resize the image.
        if let size = request.imageSize {
            phManager.requestImage(
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
            phManager.requestImageData(
                for: asset,
                options: nil
            ) {
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

public extension MediaHandler {
    
    /// Check authorization status from PHMediaLibrary.
    ///
    /// - Parameter completion: Completion closure.
    public func checkAuthorization(completion: ((Bool) -> Void)?) {
        checkAuthorization(status: PHPhotoLibrary.authorizationStatus(),
                           completion: completion)
    }
    
    /// Check authorization status from PHMediaLibrary. If media access is
    /// granted, we can initialze the PHImageManager instances - this is done
    /// so as to avoid crashes that may occur upon PHImageManager 
    /// initialization if permission is not granted.
    ///
    /// This method should be called when the app is first started.
    ///
    /// - Parameters:
    ///   - status: The authorization status being checked.
    ///
    /// - Returns: An Observable instance.
    public func rxCheckAuthorization(status: PHAuthorizationStatus)
        -> Observable<Bool>
    {
        return Observable
            .create({
                switch status {
                case .authorized:
                    $0.onNext(true)
                    
                default:
                    $0.onNext(false)
                }
                
                $0.onCompleted()
                return Disposables.create()
            })
            .doOnNext(onPermissionChecked)
    }
    
    fileprivate func onPermissionChecked(_ granted: Bool) {
        if granted && phManager == nil {
            phManager = PHImageManager()
        }
    }
}

extension MediaHandler: MediaHandlerProtocol {
    /// Check permission to access Medias SDK.
    ///
    /// - Parameters:
    ///   - status: The current authorization status.
    ///   - completion: Completion closure.
    public func checkAuthorization(status: PHAuthorizationStatus,
                                   completion: ((Bool) -> Void)?) {}
}
