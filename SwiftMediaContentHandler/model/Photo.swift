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
public struct Photo {
    public static let blank = Photo(asset: nil)
    
    public let asset: PHAsset?
    
    public var id: String {
        return asset?.localIdentifier ?? ""
    }
    
    public init(asset: PHAsset?) {
        self.asset = asset
    }
    
    public func hasLocalAsset() -> Bool {
        return asset != nil
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
