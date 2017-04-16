//
//  LocalMediaCache.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Cache for PHAsset fetched by LocalMediaDatabase.
public final class LocalMediaCache: Collection {
    fileprivate var albums: [Album]
    
    public var startIndex: Int {
        return albums.startIndex
    }
    
    public var endIndex: Int {
        return albums.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> Album {
        return albums[index]
    }
    
    /// Return an Array of cached Album instances.
    public var cachedAlbums: [Album] {
        return albums
    }
    
    /// Return an Array of cached LocalMedia instances.
    public var cachedMedia: [LocalMedia] {
        return cachedAlbums.flatMap({$0.albumMedia})
    }
    
    init() {
        albums = []
    }
    
    /// Cache an Album instance.
    ///
    /// - Parameter album: An Album instance.
    public func cache(album: Album) {
        if album.hasName {
            let name = album.albumName
            
            if let existing = cachedAlbum(forName: name) {
                existing.appendMedia(from: album)
            } else {
                albums.append(album)
            }
        }
    }
    
    /// Return a cached Album instance, if it exists.
    ///
    /// - Parameter name: The name to identify the Album.
    /// - Returns: An optional Album instance.
    public func cachedAlbum(forName name: String) -> Album? {
        return albums.elementSatisfying({$0.albumName == name})
    }
    
    /// Builder for LocalMediaCache
    public final class Builder {
        fileprivate let cache: LocalMediaCache
        
        init() {
            cache = LocalMediaCache()
        }
        
        public func build() -> LocalMediaCache {
            return cache
        }
    }
}

public extension LocalMediaCache {
    
    /// Return a LocalMediaCache.Builder instance.
    ///
    /// - Returns: A LocalMediaCache.Builder instance.
    public static func builder() -> Builder {
        return Builder()
    }
}
