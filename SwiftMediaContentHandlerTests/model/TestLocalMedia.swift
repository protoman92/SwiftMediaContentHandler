//
//  LocalMedia.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos

extension LocalMedia {
    public static var fake = LocalMedia
        .builder()
        .with(asset: PHAsset())
        .build()
    
    public static var noMedia = LocalMedia.builder().build()
}
