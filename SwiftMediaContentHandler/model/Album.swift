//
//  Album.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 7/31/16.
//  Copyright © 2016 Swiften. All rights reserved.
//

import Photos
import SwiftUtilities

/// Classes that implement this protocol must be able to hold local media
/// information.
public protocol AlbumType {
    
    /// Get the album name.
    var albumName: String { get }
    
    /// Get the album's media instances.
    var albumMedia: [LMTResult] { get }
    
    /// Get the number of LocalMediaType instances.
    var count: Int { get }
    
    func hasSameName<A: AlbumType>(as album: A) -> Bool
}

/// This class represents a collection of LocalMedia, and each instance has
/// a name that can be used to identify itself.
public struct Album: Collection {
    public var startIndex: Int {
        return medias.startIndex
    }
    
    public var endIndex: Int {
        return medias.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> LMTResult {
        return medias[index]
    }
    
    /// The Album's name as found by PHPhotoLibrary.
    fileprivate var name: String
    
    
    /// The Album's PHAsset instances, wrapped in LocalMedia.
    fileprivate var medias: [LMTResult]
    
    /// This is used for MediaDatabase's filterAlbumWithNoName.
    public var hasName: Bool {
        return name.isNotEmpty
    }
    
    /// This getter is used to hide the Album's name field, so that it cannot
    /// be changed dynamically.
    public var albumName: String {
        return name
    }
    
    /// This getter is used to hide the Album's medias field, so that it
    /// cannot be changed dynamically.
    public var albumMedia: [LMTResult] {
        return medias
    }
    
    fileprivate init() {
        name = ""
        medias = []
    }
    
    /// Check if two Albums have the same name.
    ///
    /// - Parameter album: An Album instance.
    /// - Returns: A Bool value.
    public func hasSameName<A: AlbumType>(as album: A) -> Bool {
        return albumName == album.albumName
    }
    
    /// Builder for Album.
    public final class Builder {
        fileprivate var album: Album
        
        fileprivate init() {
            album = Album()
        }
        
        /// Set the album's name.
        ///
        /// - Parameter name: A String value.
        /// - Returns: The current Builder instance.
        public func with(name: String) -> Builder {
            album.name = name
            return self
        }
        
        /// Add photos to the album's photos Array.
        ///
        /// - Parameter photos: An Array of Photo instances.
        /// - Returns: The current Builder instance.
        public func add(medias: [LMTResult]) -> Builder {
            album.medias.append(contentsOf: medias)
            return self
        }
        
        /// Add assets, wrapped in Photo instances, to the album's photos 
        /// Array.
        ///
        /// - Parameter assets: An Array of PHAsset instances.
        /// - Returns: The current Builder instance.
        public func add(assets: [PHAsset]) -> Builder {
            return add(medias: assets
                .map({LocalMedia.builder().with(asset: $0).build()})
                .map(LMTResult.init))
        }
        
        /// Get album.
        ///
        /// - Returns: An Album instance.
        public func build() -> Album {
            return album
        }
    }
}

public extension Album {
    
    /// Get a Builder instance.
    ///
    /// - Returns: A Builder instance.
    public static func builder() -> Builder {
        return Builder()
    }
    
    /// Get an empty Album.
    ///
    /// - Returns: An AlbumType instance.
    public static func empty() -> AlbumType {
        return builder().build()
    }
}

extension Album: CustomStringConvertible {
    public var description: String {
        return "Album: \(name), item count: \(medias.count)"
    }
}

extension Album: AlbumType {}
