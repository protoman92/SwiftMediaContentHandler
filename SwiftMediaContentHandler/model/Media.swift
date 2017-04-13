//
//  Media.swift
//  Heartland Chefs
//
//  Created by Hai Pham on 1/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// This struct hides PHAsset implementation.
public class Media {
    public static let blank = Media()
    
    public var asset: PHAsset?
    
    public var id: String {
        return asset?.localIdentifier ?? ""
    }
    
    fileprivate init() {}
    
    public func hasLocalAsset() -> Bool {
        return asset != nil
    }
    
    public class Builder {
        fileprivate let media: Media
        
        fileprivate init() {
            media = Media()
        }
        
        /// Set the Media's asset instance.
        ///
        /// - Parameter asset: A PHAsset instance.
        /// - Returns: The current Builder instance.
        public func with(asset: PHAsset?) -> Builder {
            media.asset = asset
            return self
        }
        
        public func build() -> Media {
            return media
        }
    }
}

public extension Media {
    public static func builder() -> Builder {
        return Builder()
    }
}

public protocol MediaProtocol {
    var asset: PHAsset? { get }
}

extension Media: MediaProtocol {}

extension Media: CustomComparisonProtocol {
    public func equals(object: Media?) -> Bool {
        return object?.id == id
    }
}

extension PHAsset: CustomComparisonProtocol {
    public func equals(object: PHAsset?) -> Bool {
        return object == self
    }
}

extension Media: Equatable {}

public func ==(first: Media, second: Media) -> Bool {
    return first.id == second.id
}

extension Array where Element: MediaProtocol {
    public var assets: [PHAsset] {
        return flatMap({$0.asset})
    }
}
