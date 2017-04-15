//
//  ImageSize.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/11/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit

/// Default image sizes to be used when getting local media.
public struct ImageSize {
    
    /// Medium-sized images
    public static let MEDIUM: CGFloat = 300
    
    /// Full-sized images
    public static let FULL: CGFloat = 800
    
    public static let SQUARED_MEDIUM: CGSize =
        CGSize(width: ImageSize.MEDIUM, height: ImageSize.MEDIUM)
    
    public static let SQUARED_FULL: CGSize =
        CGSize(width: ImageSize.FULL, height: ImageSize.FULL)
}
