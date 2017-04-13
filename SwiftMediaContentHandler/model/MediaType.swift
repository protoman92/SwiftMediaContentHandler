//
//  MediaType.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

public enum MediaType {
    case image
    
    public var assetType: PHAssetMediaType {
        switch self {
        case .image:
            return .image
        }
    }
}

extension MediaType: CustomComparisonProtocol {
    public func equals(object: MediaType?) -> Bool {
        return self == object
    }
}

public protocol MediaTypeProtocol {
    var assetType: PHAssetMediaType { get }
}

extension MediaType: MediaTypeProtocol {}

public extension Array where Element: MediaTypeProtocol {
    
    /// Get all asset types, from each element in the Array.
    public var assetTypes: [PHAssetMediaType] {
        return map({$0.assetType})
    }
    
    /// Get all asset type raw values.
    public var assetTypeRawValues: [Int] {
        return assetTypes.map({$0.rawValue})
    }
}
