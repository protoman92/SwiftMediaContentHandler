//
//  TestMediaHandler.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxSwift
import SwiftUtilities
import SwiftUtilitiesTests

class TestMediaHandler: MediaHandler {
    let request_withBaseRequest: FakeDetails
    let request_withWebRequest: FakeDetails
    let request_withWebImageRequest: FakeDetails
    let request_withLocalRequest: FakeDetails
    let request_withLocaImageRequest: FakeDetails
    let rxRequest_withBaseRequest: FakeDetails
    
    var fetchActualData: Bool
    
    override init() {
        request_withBaseRequest = FakeDetails.builder().build()
        request_withWebRequest = FakeDetails.builder().build()
        request_withWebImageRequest = FakeDetails.builder().build()
        request_withLocalRequest = FakeDetails.builder().build()
        request_withLocaImageRequest = FakeDetails.builder().build()
        rxRequest_withBaseRequest = FakeDetails.builder().build()
        fetchActualData = true
        super.init()
    }
    
    override func requestMedia(with request: MediaRequest,
                               andThen complete: @escaping MediaCallback) {
        request_withBaseRequest.onMethodCalled(withParameters: request)
        super.requestMedia(with: request, andThen: complete)
    }
    
    override func requestWebMedia(with request: WebRequest,
                                  andThen complete: @escaping MediaCallback) {
        request_withWebRequest.onMethodCalled(withParameters: request)
        super.requestWebMedia(with: request, andThen: complete)
    }
    
    override func requestLocalMedia(with request: LocalRequest,
                                    andThen complete: @escaping MediaCallback) {
        request_withLocalRequest.onMethodCalled(withParameters: request)
        super.requestLocalMedia(with: request, andThen: complete)
    }
    
    override func requestLocalImage(with request: LocalImageRequest,
                                    andThen complete: @escaping MediaCallback) {
        request_withLocaImageRequest.onMethodCalled(withParameters: request)
        
        if fetchActualData {
            super.requestLocalImage(with: request, andThen: complete)
        }
    }
    
    override func requestWebImage(with request: WebImageRequest,
                                  andThen complete: @escaping MediaCallback) {
        request_withWebImageRequest.onMethodCalled(withParameters: request)
        
        if fetchActualData {
            super.requestWebImage(with: request, andThen: complete)
        }
    }
    
    override func rxRequest(with request: MediaRequest) -> Observable<Any> {
        rxRequest_withBaseRequest.onMethodCalled(withParameters: request)
        return super.rxRequest(with: request)
    }
}

extension TestMediaHandler: FakeProtocol {
    func reset() {
        [
            request_withBaseRequest,
            request_withLocalRequest,
            request_withLocaImageRequest,
            request_withWebRequest,
            request_withWebImageRequest,
            rxRequest_withBaseRequest
        ].forEach({$0.reset()})
    }
}
