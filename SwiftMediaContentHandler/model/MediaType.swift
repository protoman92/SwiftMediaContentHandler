//
//  MediaType.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// This enum encapsulates PHAssetMediaType.
public enum MediaType {
    case image
    case video
    case audio
    case unknown
    
    /// Get the associated PHAssetMediaType.
    public var assetType: PHAssetMediaType {
        switch self {
        case .image:
            return .image
            
        case .video:
            return .video
            
        case .audio:
            return .audio
            
        case .unknown:
            return .unknown
        }
    }
}

public extension MediaType {
    
    /// Get the associated MediaType from PHAssetMediaType.
    ///
    /// - Parameter assetType: A PHAssetMediaType instance.
    /// - Returns: A MediaType instance.
    public static func from(assetType: PHAssetMediaType) -> MediaType {
        switch assetType {
        case .image:
            return .image
            
        case .video:
            return .video
            
        case .audio:
            return .audio
            
        case .unknown:
            return .unknown
        }
    }
}

extension MediaType: CustomComparisonType {
    public func equals(object: MediaType?) -> Bool {
        return self == object
    }
}
