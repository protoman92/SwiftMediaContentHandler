//
//  AlbumHolderTest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/29/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities
import SwiftUtilitiesTests
import XCTest

final class AlbumHolderTest: XCTestCase {
    public func test_addItemToAlbumHolder_shouldSucceed() {
        // Setup
        let albumCount = 20
        let itemsPerAlbum = 130
        let tries = 49
        let albumHolder = AlbumHolder()
        
        let albums = (0..<albumCount).map(toVoid)
            .map(Album.builder)
            .map({$0.with(name: String.random(withLength: 10))})
            .map({$0.add(media: Array(repeating: {_ in
                LocalMedia.fake()}, for: itemsPerAlbum
            ))})
            .map({$0.build()})
            .map(AlbumResult.init)
        
        let expect = expectation(description: "Should have succeeded")
        
        // When
        for i1 in 0..<tries {
            for (i2, album) in albums.enumerated() {
                background(.background) {
                    albumHolder.safeAppend(album)
                    
                    if i1 == tries - 1 && i2 == albums.count - 1 {
                        expect.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 100, handler: nil)
        
        // Then
        let names = albumHolder.albumNames
        let uniqueNames = Set(names).map(eq)
        XCTAssertEqual(names.count, uniqueNames.count)
        
        for album in albumHolder.albums {
            XCTAssertEqual(album.count, itemsPerAlbum * tries)
        }
    }
}
