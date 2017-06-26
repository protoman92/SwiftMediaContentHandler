//
//  MediaDatabaseMessage.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Common messages for LocalMediaDatabase.
public protocol MediaDatabaseMessageType {
    
    /// Get the error message for when permission is not granted.
    var permissionNotGranted: String { get }
    
    /// Get the default Album name that will be used when a PHAssetCollection
    /// has no title.
    var defaultAlbumName: String { get }
}

/// Default media message provider.
public struct DefaultMediaMessage {}

extension DefaultMediaMessage: MediaDatabaseMessageType {
    
    /// Get the error message for when permission is not granted.
    public var permissionNotGranted: String {
        return "media.error.permissionNotGranted".localized
    }
    
    /// Get the default Album name that will be used when a PHAssetCollection
    /// has no title.
    public var defaultAlbumName: String {
        return "media.title.untitled".localized
    }
}
