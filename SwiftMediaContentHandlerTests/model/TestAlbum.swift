//
//  TestAlbum.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos

extension Album {
    static var fake: Album {
        return Album.builder()
            .with(name: String.random(withLength: 10))
            .add(medias: [LocalMedia.fake])
            .build()
    }
    
    static var empty: Album {
        return Album.builder().build()
    }
    
    static var noName: Album {
        return Album.builder()
            .with(name: "")
            .add(medias: [LocalMedia.fake])
            .build()
    }
}
