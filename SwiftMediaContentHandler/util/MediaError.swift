//
//  MediaError.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

/// Common error messages.
public protocol MediaErrorType {}

public extension MediaErrorType {
    public var permissionNotGranted: String {
        return "media.error.permissionNotGranted".localized
    }
    
    public var mediaHandlerUnavailable: String {
        return "media.error.handlerUnavailable".localized
    }
    
    public var mediaHandlerUnknownRequest: String {
        return "media.error.unknownRequestType".localized
    }
    
    public var mediaUnavailable: String {
        return "media.error.unavailable".localized
    }
    
    public var notAnImage: String {
        return "media.error.notAnImage".localized
    }
}
