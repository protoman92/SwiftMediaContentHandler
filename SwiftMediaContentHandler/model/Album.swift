//
//  Album.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 7/31/16.
//  Copyright © 2016 Anh Vu Mai. All rights reserved.
//

import Photos
import SwiftUtilities

public class Album: Collection {
    public var startIndex: Int {
        return medias.startIndex
    }
    
    public var endIndex: Int {
        return medias.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> LocalMedia {
        return medias[index]
    }
    
    public var name: String
    public var medias: [LocalMedia]
    
    fileprivate init() {
        name = ""
        medias = []
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
        public func add(medias: [LocalMedia]) -> Builder {
            album.medias.append(uniqueContentsOf: medias)
            return self
        }
        
        /// Add assets, wrapped in Photo instances, to the album's photos 
        /// Array.
        ///
        /// - Parameter assets: An Array of PHAsset instances.
        /// - Returns: The current Builder instance.
        public func add(assets: [PHAsset]) -> Builder {
            return add(medias: assets.map({
                LocalMedia.builder().with(asset: $0).build()
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
    
    var medias: [LocalMedia] { get set }
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
            existing.medias.appendOrReplace(uniqueContentsOf: album.medias)
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
