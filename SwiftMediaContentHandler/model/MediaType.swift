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
