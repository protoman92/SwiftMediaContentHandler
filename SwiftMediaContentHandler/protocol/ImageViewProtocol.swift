//
//  ImageViewProtocol.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/11/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import UIKit

/// Views that can display images should implement this protocol for use with
/// ImageHandler (e.g. UIImageView).
public protocol ImageViewProtocol {
    
    /// Return the UIImage that is currently displayed.
    var image: UIImage? { get set }
    
    /// Fade in an UIImage. If the UIImage is nil, we expect this ImageView
    /// to fade to its background color.
    ///
    /// - Parameters:
    ///   - image: An optional UIImage.
    ///   - completion: Completion callback for when the animation ends.
    func fadeIn(image: UIImage?, completion: ((Bool) -> Void)?)
}
