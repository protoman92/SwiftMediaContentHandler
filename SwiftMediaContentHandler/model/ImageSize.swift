//
//  ImageSize.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/11/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit

/// Default image sizes to be used when getting local media.
public enum ImageSize: CGFloat {
    /// Thumbnail-sized images
    case thumbnail = 150
    
    /// Small-sized images.
    case small = 300
    
    /// Medium-sized images
    case medium = 500
    
    /// Full-sized images
    case large = 800

    /// Get a squared CGSize with same width-length.
    public var squaredSize: CGSize {
        return CGSize(width: rawValue, height: rawValue)
    }
}

/// Classes that implement this protocol must be able to provide a squared
/// size to be used with MediaHandler.
public protocol ImageSizeProtocol {
    var rawValue: CGFloat { get }
    
    var squaredSize: CGSize { get }
}

extension ImageSize: ImageSizeProtocol {}
