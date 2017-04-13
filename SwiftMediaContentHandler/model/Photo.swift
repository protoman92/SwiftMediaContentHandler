//
//  Photo.swift
//  Heartland Chefs
//
//  Created by Hai Pham on 1/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// This struct hides PHAsset implementation.
public class Photo {
    public static let blank = Photo()
    
    public var asset: PHAsset?
    
    public var id: String {
        return asset?.localIdentifier ?? ""
    }
    
    fileprivate init() {}
    
    public func hasLocalAsset() -> Bool {
        return asset != nil
    }
    
    public class Builder {
        fileprivate let photo: Photo
        
        fileprivate init() {
            photo = Photo()
        }
        
        /// Set the photo's asset instance.
        ///
        /// - Parameter asset: A PHAsset instance.
        /// - Returns: The current Builder instance.
        public func with(asset: PHAsset?) -> Builder {
            photo.asset = asset
            return self
        }
        
        public func build() -> Photo {
            return photo
        }
    }
}

public extension Photo {
    public static func builder() -> Builder {
        return Builder()
    }
}

public protocol PhotoProtocol {
    var asset: PHAsset? { get }
}

extension Photo: PhotoProtocol {}

extension Photo: CustomComparisonProtocol {
    public func equals(object: Photo?) -> Bool {
        return object?.id == id
    }
}

extension PHAsset: CustomComparisonProtocol {
    public func equals(object: PHAsset?) -> Bool {
        return object == self
    }
}

extension Photo: Equatable {}

public func ==(first: Photo, second: Photo) -> Bool {
    return first.id == second.id
}

extension Array where Element: PhotoProtocol {
    public var assets: [PHAsset] {
        return flatMap({$0.asset})
    }
}
