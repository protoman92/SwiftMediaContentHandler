//
//  CollectionType.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/15/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

public enum MediaCollectionType {
    case smartAlbum
    
    public var collectionType: PHAssetCollectionType {
        switch self {
        case .smartAlbum:
            return .smartAlbum
        }
    }
}

extension MediaCollectionType: CustomComparisonProtocol {
    public func equals(object: MediaCollectionType?) -> Bool {
        return self == object
    }
}
