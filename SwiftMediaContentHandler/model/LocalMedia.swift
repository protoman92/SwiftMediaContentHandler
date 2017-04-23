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
    
    /// We can only set the album name after fetching PHAsset from 
    /// PHPhotoLibrary.
    fileprivate var albumName: String
    
    /// A PHAsset instance. This can used to fetch local media.
    fileprivate var asset: PHAsset?
    
    /// Return albumName. Also provides a setter because the album's name
    /// cannot be set at the Builder stage.
    public var localAlbumName: String {
        get {
            return albumName
        }
        
        set {
            albumName = newValue
        }
    }
    
    /// Return asset.
    public var localAsset: PHAsset? {
        return asset
    }
    
    public var id: String {
        return asset?.localIdentifier ?? ""
    }
    
    fileprivate init() {
        albumName = ""
    }
    
    public func hasLocalAsset() -> Bool {
        return asset != nil
    }
    
    public class Builder {
        fileprivate let media: LocalMedia
        
        fileprivate init() {
            media = LocalMedia()
        }
        
        /// Set the LocalMedia's albumName.
        ///
        /// - Parameter name: A String value.
        /// - Returns: The current Builder instance.
        public func with(albumName name: String) -> Builder {
            media.albumName = name
            return self
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

extension LocalMedia: CustomStringConvertible {
    public var description: String {
        return String(describing: asset)
    }
}

public protocol LocalMediaProtocol {
    var localAsset: PHAsset? { get }
}

extension LocalMedia: LocalMediaProtocol {}

extension LocalMedia: CustomComparisonType {
    public func equals(object: LocalMedia?) -> Bool {
        return object?.id == id
    }
}

extension PHAsset: CustomComparisonType {
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
        return flatMap({$0.localAsset})
    }
}
