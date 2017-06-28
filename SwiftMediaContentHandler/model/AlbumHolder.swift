//
//  AlbumHolder.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/28/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities

/// This class provides some convenient methods to handle multiple AlbumResult.
public final class AlbumHolder {
    fileprivate var results: [AlbumResult]
    
    /// Get all valid AlbumType instances.
    public var albums: [AlbumType] {
        return results.flatMap({$0.value})
    }
    
    /// Get results.
    public var albumResults: [AlbumResult] {
        return results
    }
    
    /// Get all valid album names.
    public var albumNames: [String] {
        return results.flatMap({$0.value}).map({$0.albumName})
    }
    
    /// Get the total number of LMTResult instances.
    public var mediaCount: Int {
        return results.flatMap({$0.value}).map({$0.count}).reduce(0, +)
    }
    
    public init() {
        results = [AlbumResult]()
    }
    
    /// Append a new AlbumResult with lock.
    ///
    /// - Parameters:
    ///   - result: An AlbumResult instance.
    ///   - completion: A closure that accepts Int as parameter.
    public func safeAppend(_ result: AlbumResult,
                           completion: ((Int) -> Void) = toVoid) {
        synchronized(self, then: {
            completion(append(result))
        })
    }
    
    /// Append a new AlbumResult, or replace an existing one if applicable.
    ///
    /// - Parameter result: An AlbumResult instance.
    /// - Returns: An Int value indicating the index at which the new 
    ///            AlbumResult is inserted/appended. We can use it to update
    ///            the relevant UI components.
    @discardableResult
    func append(_ result: AlbumResult) -> Int {
        let albums = self.albums
        
        if let album = result.value, let index = albums.index(where: {
            $0.hasSameName(as: album)
        }), let existing = albums.element(at: index) {
            let newAlbum = existing.appending(contentsOf: album)
            results[index] = AlbumResult(newAlbum)
            return index
        } else {
            let oldCount = results.count
            results.append(result)
            return oldCount
        }
    }
}

extension AlbumHolder: Collection {
    public var startIndex: Int {
        return results.startIndex
    }
    
    public var endIndex: Int {
        return results.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return Swift.min(i + 1, endIndex)
    }
    
    public subscript(index: Int) -> AlbumResult {
        return results[index]
    }
}
