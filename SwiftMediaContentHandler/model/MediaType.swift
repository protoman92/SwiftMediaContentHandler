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
    
    public var assetType: PHAssetMediaType {
        switch self {
        case .image:
            return .image
            
        case .video:
            return .video
            
        case .audio:
            return .audio
        }
    }
}

extension MediaType: CustomComparisonProtocol {
    public func equals(object: MediaType?) -> Bool {
        return self == object
    }
}
