//
//  AlbumHolder.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/28/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities

/// This class provides some convenient methods to handle multiple AlbumEither.
public final class AlbumHolder {
    fileprivate var eithers: [AlbumEither]
    
    /// Get all valid AlbumType instances.
    public var albums: [AlbumType] {
        return eithers.flatMap({$0.value})
    }
    
    /// Get results.
    public var albumEithers: [AlbumEither] {
        return eithers
    }
    
    /// Get all valid album names.
    public var albumNames: [String] {
        return eithers.flatMap({$0.value}).map({$0.albumName})
    }
    
    /// Get the total number of LMTEither instances.
    public var mediaCount: Int {
        return eithers.flatMap({$0.value}).map({$0.count}).reduce(0, +)
    }
    
    public init() {
        eithers = [AlbumEither]()
    }
    
    /// Append a new AlbumEither with lock.
    ///
    /// - Parameters:
    ///   - result: An AlbumEither instance.
    ///   - completion: A closure that accepts Int as parameter.
    public func safeAppend(_ result: AlbumEither,
                           completion: ((Int) -> Void) = toVoid) {
        synchronized(self, then: {
            completion(append(result))
        })
    }
    
    /// Append a new AlbumEither, or replace an existing one if applicable.
    ///
    /// - Parameter either: An AlbumEither instance.
    /// - Returns: An Int value indicating the index at which the new 
    ///            AlbumEither is inserted/appended. We can use it to update
    ///            the relevant UI components.
    @discardableResult
    func append(_ either: AlbumEither) -> Int {
        let albums = self.albums
        
        if let album = either.value, let index = albums.index(where: {
            $0.hasSameName(as: album)
        }), let existing = albums.element(at: index) {
            let newAlbum = existing.appending(contentsOf: album)
            eithers[index] = AlbumEither.right(newAlbum)
            return index
        } else {
            let oldCount = eithers.count
            eithers.append(either)
            return oldCount
        }
    }
}

extension AlbumHolder: Collection {
    public var startIndex: Int {
        return eithers.startIndex
    }
    
    public var endIndex: Int {
        return eithers.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> AlbumEither {
        return eithers[index]
    }
}
