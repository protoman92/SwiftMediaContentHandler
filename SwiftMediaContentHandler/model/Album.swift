//
//  Album.swift
//  Sellfie
//
//  Created by Hai Pham on 7/31/16.
//  Copyright © 2016 Anh Vu Mai. All rights reserved.
//

import Photos
import SwiftUtilities

public class Album: Collection {
    public var startIndex: Int {
        return photos.startIndex
    }
    
    public var endIndex: Int {
        return photos.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> Photo {
        return photos[index]
    }
    
    public var name: String
    public var photos: [Photo]
    
    fileprivate init() {
        name = ""
        photos = []
    }
    
    public class Builder {
        fileprivate let album: Album
        
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
        public func add(photos: [Photo]) -> Builder {
            album.photos.append(uniqueContentsOf: photos)
            return self
        }
        
        /// Add assets, wrapped in Photo instances, to the album's photos 
        /// Array.
        ///
        /// - Parameter assets: An Array of PHAsset instances.
        /// - Returns: The current Builder instance.
        public func add(assets: [PHAsset]) -> Builder {
            return add(photos: assets.map({
                Photo.builder().with(asset: $0).build()
            }))
        }
        
        public func build() -> Album {
            return album
        }
    }
}

public extension Album {
    public static func builder() -> Builder {
        return Builder()
    }
}

public protocol AlbumProtocol: class {
    var name: String { get set }
    
    var photos: [Photo] { get set }
}

extension Album: AlbumProtocol {}

public extension Array where Element: AlbumProtocol {
    
    /// Append unique Photo instances from another Album.
    ///
    /// - Parameter album: The Album to get Photo instances from.
    public mutating func append(uniqueAssetsFrom album: Element) {
        if
            let index = index(where: {$0.name == album.name}),
            let existing = element(at: index)
        {
            existing.photos.appendOrReplace(uniqueContentsOf: album.photos)
        } else {
            self.append(album)
        }
    }
    
    /// Append unique Photo instances from an Array of Album.
    ///
    /// - Parameter albums: An Array of Album instances to get Photo from.
    public mutating func append(uniqueAlbumContentsOf albums: [Element]) {
        for album in albums {
            append(uniqueAssetsFrom: album)
        }
    }
}
