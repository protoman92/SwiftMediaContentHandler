//
//  LocalMedia.swift
//  SwiftLocalMediaContentHandler
//
//  Created by Hai Pham on 1/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// This class hides PHAsset implementation.
public class LocalMedia {
    public static let blank = LocalMedia()
    
    public var asset: PHAsset?
    
    public var id: String {
        return asset?.localIdentifier ?? ""
    }
    
    fileprivate init() {}
    
    public func hasLocalAsset() -> Bool {
        return asset != nil
    }
    
    public class Builder {
        fileprivate let media: LocalMedia
        
        fileprivate init() {
            media = LocalMedia()
        }
        
        /// Set the LocalMedia's asset instance.
        ///
        /// - Parameter asset: A PHAsset instance.
        /// - Returns: The current Builder instance.
        public func with(asset: PHAsset?) -> Builder {
            media.asset = asset
            return self
        }
        
        public func build() -> LocalMedia {
            return media
        }
    }
}

public extension LocalMedia {
    public static func builder() -> Builder {
        return Builder()
    }
}

public protocol LocalMediaProtocol {
    var asset: PHAsset? { get }
}

extension LocalMedia: LocalMediaProtocol {}

extension LocalMedia: CustomComparisonProtocol {
    public func equals(object: LocalMedia?) -> Bool {
        return object?.id == id
    }
}

extension PHAsset: CustomComparisonProtocol {
    public func equals(object: PHAsset?) -> Bool {
        return object == self
    }
}

extension LocalMedia: Equatable {}

public func ==(first: LocalMedia, second: LocalMedia) -> Bool {
    return first.id == second.id
}

extension Array where Element: LocalMediaProtocol {
    public var assets: [PHAsset] {
        return flatMap({$0.asset})
    }
}
