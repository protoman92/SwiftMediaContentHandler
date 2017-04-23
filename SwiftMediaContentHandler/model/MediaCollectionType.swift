//
//  CollectionType.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/15/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// This enum encapsulates PHAssetCollectionType.
public enum MediaCollectionType {
    case album
    case moment
    case smartAlbum
    
    public var collectionType: PHAssetCollectionType {
        switch self {
        case .album:
            return .album
            
        case .moment:
            return .moment
            
        case .smartAlbum:
            return .smartAlbum
        }
    }
}

extension MediaCollectionType: CustomComparisonType {
    public func equals(object: MediaCollectionType?) -> Bool {
        return self == object
    }
}
