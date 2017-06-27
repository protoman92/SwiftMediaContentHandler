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
    fileprivate var albumResult: [AlbumResult]
    
    /// Get all valid AlbumType instances.
    public var albums: [AlbumType] {
        return albumResult.flatMap({$0.value})
    }
    
    fileprivate init() {
        albumResult = [AlbumResult]()
    }
    
    /// Append a new AlbumResult, or replace an existing one if applicable.
    ///
    /// - Parameter result: An AlbumResult instance.
    fileprivate func append(albumResult result: AlbumResult) {
        let albums = self.albums
        
        if let album = result.value, let index = albums.index(where: {
            $0.hasSameName(as: album)
        }), let existing = albums.element(at: index) {
            let newAlbum = existing.appending(contentsOf: album)
            albumResult[index] = AlbumResult(newAlbum)
        } else {
            albumResult.append(result)
        }
    }
}
