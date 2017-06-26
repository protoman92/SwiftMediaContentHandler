//
//  LocalMedia.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import SwiftUtilitiesTests

extension LocalMedia {
    
    /// Get a fake LocalMedia instance.
    ///
    /// - Returns: A LocalMedia instance.
    public static func fake() -> LocalMedia {
        return LocalMedia.builder()
            .with(asset: TestPHAsset())
            .with(albumName: String.random(withLength: 10))
            .build()
    }
}
