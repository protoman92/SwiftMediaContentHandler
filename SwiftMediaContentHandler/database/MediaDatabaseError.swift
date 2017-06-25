//
//  MediaDatabaseError.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Common error messages for LocalMediaDatabase.
public protocol MediaDatabaseErrorType {}

public extension MediaDatabaseErrorType {
    public var permissionNotGranted: String {
        return "media.error.permissionNotGranted".localized
    }
}
