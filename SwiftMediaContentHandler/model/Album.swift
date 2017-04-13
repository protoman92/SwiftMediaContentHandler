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
    
    public let name: String
    public var photos: [Photo]
    
    /// Construct an Album instance.
    ///
    /// - Parameters:
    ///   - name: The Album's name.
    ///   - photos: The Array of PHAsset to populate the Album's photos Array.
    public convenience init(name: String, photos: [PHAsset]) {
        self.init(name: name, photos: photos.flatMap({Photo(asset: $0)}))
    }
    
    /// Construct an Album instance.
    ///
    /// - Parameters:
    ///   - name: The Album's name.
    ///   - photos: The Array of Photo to populate the Album's photos Array.
    public init(name: String, photos: [Photo]) {
        self.name = name
        self.photos = photos
    }
    
    /// Same as above, but uses an empty Photo Array.
    ///
    ///   - name: The Album's name.
    public convenience init(name: String) {
        self.init(name: name, photos: [Photo]())
    }
}

extension Album: AlbumProtocol {}

public protocol AlbumProtocol: class {
    var name: String { get }
    
    var photos: [Photo] { get set }
}

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
