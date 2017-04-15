//
//  MediaError.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/14/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

public class MediaError {
    public static var permissionNotGranted: String {
        return "media.error.permissionNotGranted".localized
    }
    
    public static var mediaHandlerUnavailable: String {
        return "media.error.handlerUnavailable".localized
    }
    
    public static var mediaHandlerUnknownRequest: String {
        return "media.error.unknownRequestType".localized
    }
    
    public static var mediaUnavailable: String {
        return "media.error.unavailable".localized
    }
    
    public static var notAnImage: String {
        return "media.error.notAnImage".localized
    }
}
