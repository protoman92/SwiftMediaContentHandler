//
//  MediaRequest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/13/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Foundation
import UIKit

/// Subclasses of this class shall be used for different types of media, from
/// different sources.
public class MediaRequest: NSObject {
    public class BaseBuilder {
        fileprivate let request: MediaRequest
        
        init(request: MediaRequest) {
            self.request = request
        }
        
        public func build() -> MediaRequest {
            return request
        }
    }
}

/// This request base class deals with remote media downloading.
public class WebRequest: MediaRequest {
    fileprivate var urlString: String?

    /// Parse the urlString into a URL instance.
    var url: URL? {
        guard let urlString = self.urlString else {
            return nil
        }

        return URL(string: urlString)
    }
    
    public class WebBuilder: BaseBuilder {
        fileprivate var webRequest: WebRequest? {
            return request as? WebRequest
        }
        
        /// Set the url variable for request.
        ///
        /// - Parameter url: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(url: String) -> WebBuilder {
            webRequest?.urlString = url
            return self
        }
    }
}

/// Download image from the web.
public final class WebImageRequest: WebRequest {
    public final class Builder: WebBuilder {
        init() {
            super.init(request: WebImageRequest())
        }
    }
}

/// This request base class deals with local asset loading.
public class LocalRequest: MediaRequest {
    
    /// If this variable is set, local source.
    fileprivate var media: LocalMedia?
    
    var mediaAsset: LocalMedia? {
        return media
    }
    
    public class LocalBuilder: MediaRequest.BaseBuilder {
        fileprivate var localRequest: LocalRequest? {
            return request as? LocalRequest
        }
        
        /// Set the media variable for request.
        ///
        /// - Parameter photo: A Media instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(media: LocalMedia) -> LocalBuilder {
            localRequest?.media = media
            return self
        }
    }
}

/// Download image locally.
public final class LocalImageRequest: LocalRequest {
    
    /// If this variable is nil, request an image with the original size.
    fileprivate var size: CGSize?
    
    var imageSize: CGSize? {
        return size
    }
    
    public final class Builder: LocalBuilder {
        fileprivate override var localRequest: LocalImageRequest? {
            return super.localRequest as? LocalImageRequest
        }
        
        init() {
            super.init(request: LocalImageRequest())
        }
        
        /// Set the size variable for request.
        ///
        /// - Parameter size: A CGSize instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(size: CGSize) -> Builder {
            localRequest?.size = size
            return self
        }
    }
}

public extension WebImageRequest {
    public static func builder() -> Builder {
        return Builder()
    }
}

public extension LocalImageRequest {
    public static func builder() -> Builder {
        return Builder()
    }
}
