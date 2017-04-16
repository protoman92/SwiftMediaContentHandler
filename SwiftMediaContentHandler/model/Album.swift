//
//  Album.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 7/31/16.
//  Copyright © 2016 Anh Vu Mai. All rights reserved.
//

import Photos
import SwiftUtilities

/// This class represents a collection of LocalMedia, and each instance has
/// a name that can be used to identify itself.
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
    
    /// The Album's name as found by PHPhotoLibrary.
    fileprivate var name: String
    
    
    /// The Album's PHAsset instances, wrapped in LocalMedia.
    fileprivate var medias: [LocalMedia]
    
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
    public var albumMedia: [LocalMedia] {
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
    public func hasSameName<A: AlbumProtocol>(as album: A) -> Bool {
        return albumName == album.albumName
    }
    
    /// Append another Album's media instances.
    ///
    /// - Parameter album: An Album instance.
    /// - Returns: An Int value representing number of unique LocalMedie added.
    @discardableResult
    public func appendMedia<A: AlbumProtocol>(from album: A) -> Int {
        return medias.appendOrReplace(uniqueContentsOf: album.albumMedia)
    }
    
    /// We need to set the albumName for each LocalMedia instance. This method
    /// is called during Builder.build() to ensure that the albumName as
    /// well as the LocalMedia Array have been initialized.
    fileprivate func onInstanceBuilt() {
        let albumName = self.albumName
        forEach({$0.localAlbumName = albumName})
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
            album.onInstanceBuilt()
            return album
        }
    }
}

public extension Album {
    public static func builder() -> Builder {
        return Builder()
    }
}

extension Album: CustomStringConvertible {
    public var description: String {
        return "Album: \(name), item count: \(medias.count)"
    }
}

/// Classes that implement this protocol must be able to hold local media
/// information.
public protocol AlbumProtocol: class {
    var albumName: String { get }
    
    var albumMedia: [LocalMedia] { get }
    
    func hasSameName<A: AlbumProtocol>(as album: A) -> Bool
    
    @discardableResult
    func appendMedia<A: AlbumProtocol>(from album: A) -> Int
}

extension Album: AlbumProtocol {}

public extension Array where Element: AlbumProtocol {
    
    /// Append unique Photo instances from another Album.
    ///
    /// - Parameter album: The Album to get Photo instances from.
    public mutating func append(uniqueAssetsFrom album: Element) {
        if
            let index = index(where: {$0.hasSameName(as: album)}),
            let existing = element(at: index)
        {
            existing.appendMedia(from: album)
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
