//
//  MediaDatabaseError.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Common error messages for LocalMediaDatabase.
public protocol MediaDatabaseErrorType {
    
    /// Get the error message for when permission is not granted.
    var permissionNotGranted: String { get }
}

/// Default media error provider.
public struct DefaultMediaError {}

extension DefaultMediaError: MediaDatabaseErrorType {
    
    /// Get the error message for when permission is not granted.
    public var permissionNotGranted: String {
        return "media.error.permissionNotGranted".localized
    }
}
