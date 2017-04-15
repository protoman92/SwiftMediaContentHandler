//
//  TestMediaRequest.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/16/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

extension MediaRequest {
    
    /// This method is only used for testing. For non-testing environment,
    /// initializers for base MediaRequest classes should not be exposed.
    ///
    /// - Returns: A MediaRequest.Builder instance.
    static func baseBuilder() -> MediaRequest.BaseBuilder {
        return MediaRequest.BaseBuilder(request: MediaRequest())
    }
}

extension WebRequest {

    /// This method is only used for testing. For non-testing environment,
    /// initializers for base WebRequest classes should not be exposed.
    ///
    /// - Returns: A WebRequest instance.
    static func webBuilder() -> WebRequest.WebBuilder {
        return WebRequest.WebBuilder(request: WebRequest())
    }
}

extension LocalRequest {
    
    /// This method is only used for testing. For non-testing environment,
    /// initializers for base LocalRequest classes should not be exposed.
    ///
    /// - Returns: A LocalRequest instance.
    static func localBuilder() -> LocalRequest.LocalBuilder {
        return LocalRequest.LocalBuilder(request: LocalRequest())
    }
}
