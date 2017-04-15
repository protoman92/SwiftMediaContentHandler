//
//  TestMediaHandler.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Photos
import RxSwift
import SwiftUtilities
import SwiftUtilitiesTests

class TestMediaHandler: MediaHandler {
    let request_withWebImageRequest: FakeDetails
    let request_withLocaImageRequest: FakeDetails
    
    var fetchActualData: Bool
    var isPhotoAccessAuthorized: Bool
    var returnValidMedia: Bool
    
    override init() {
        request_withWebImageRequest = FakeDetails.builder().build()
        request_withLocaImageRequest = FakeDetails.builder().build()
        fetchActualData = true
        isPhotoAccessAuthorized = true
        returnValidMedia = true
        super.init()
    }
    
    /// To simulate authorization status, we can change isPhotoAccessAuthorized
    /// flag.
    ///
    /// - Returns: An Observable instance.
    override func rxIsAuthorized() -> Observable<Bool> {
        if isPhotoAccessAuthorized {
            return Observable.just(true)
        } else {
            return Observable.just(false)
        }
    }
    
    override func requestLocalImage(with request: LocalImageRequest,
                                    using manager: PHImageManager,
                                    andThen complete: @escaping MediaCallback) {
        request_withLocaImageRequest.onMethodCalled(withParameters: request)
        
        if fetchActualData {
            super.requestLocalImage(with: request,
                                    using: manager,
                                    andThen: complete)
        } else {
            if returnValidMedia {
                complete(UIImage(), nil)
            } else {
                complete(nil, Exception(MediaError.mediaUnavailable))
            }
        }
    }
    
    override func requestWebImage(with request: WebImageRequest,
                                  andThen complete: @escaping MediaCallback) {
        request_withWebImageRequest.onMethodCalled(withParameters: request)
        
        if fetchActualData {
            super.requestWebImage(with: request, andThen: complete)
        } else {
            if returnValidMedia {
                complete(UIImage(), nil)
            } else {
                complete(nil, Exception(MediaError.mediaUnavailable))
            }
        }
    }
}

extension TestMediaHandler: FakeProtocol {
    func reset() {
        [
            request_withLocaImageRequest,
            request_withWebImageRequest
        ].forEach({$0.reset()})
        
        fetchActualData = true
        isPhotoAccessAuthorized = true
        returnValidMedia = true
    }
}
