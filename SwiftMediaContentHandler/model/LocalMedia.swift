//
//  LocalMedia.swift
//  SwiftLocalMediaContentHandler
//
//  Created by Hai Pham on 1/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// Implement this protocol to provide local media information.
public protocol LocalMediaType {
    
    /// Get the associated album name.
    var localAlbumName: String { get }
    
    /// Get the associated PHAsset instance.
    var localAsset: PHAsset? { get }
}

public extension LocalMediaType {
    
    /// Get the PHAsset id, if available.
    public var id: String {
        return localAsset?.localIdentifier ?? ""
    }
    
    /// Check whether the PHAsset instance is available.
    ///
    /// - Returns: A Bool value.
    public func hasLocalAsset() -> Bool {
        return localAsset != nil
    }
}

/// This class hides PHAsset implementation.
public struct LocalMedia {
    
    /// Get a blank LocalMedia instance.
    ///
    /// - Returns: A LocalMedia instance.
    public static func blank() -> LocalMedia {
        return LocalMedia()
    }
    
    /// The album name.
    fileprivate var albumName: String
    
    /// A PHAsset instance. This can used to fetch local media.
    fileprivate var asset: PHAsset?
    
    /// Get albumName.
    public var localAlbumName: String {
        return albumName
    }
    
    /// Get asset.
    public var localAsset: PHAsset? {
        return asset
    }
    
    fileprivate init() {
        albumName = ""
    }
    
    /// Builder class for LocalMedia.
    public final class Builder {
        fileprivate var media: LocalMedia
        
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
        
        /// Get media instance.
        ///
        /// - Returns: A LocalMedia instance.
        public func build() -> LocalMedia {
            return media
        }
    }
}

public extension LocalMedia {
    
    /// Get a Builder instance.
    ///
    /// - Returns: A Builder instance.
    public static func builder() -> Builder {
        return Builder()
    }
}

extension LocalMedia: CustomStringConvertible {
    public var description: String {
        return "\(localAlbumName) - \(String(describing: asset))"
    }
}

extension LocalMedia: LocalMediaType {}

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
