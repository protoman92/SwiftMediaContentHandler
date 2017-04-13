//
//  TestImageHandler.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 4/12/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import RxSwift
import SwiftUtilities
import SwiftUtilitiesTests

class TestImageHandler: ImageHandler {
    let request_withBaseRequest: FakeDetails
    let request_withWebRequest: FakeDetails
    let request_withLocalRequest: FakeDetails
    let rxRequest_withBaseRequest: FakeDetails
    
    var fetchActualData: Bool
    
    override init() {
        request_withBaseRequest = FakeDetails.builder().build()
        request_withWebRequest = FakeDetails.builder().build()
        request_withLocalRequest = FakeDetails.builder().build()
        rxRequest_withBaseRequest = FakeDetails.builder().build()
        fetchActualData = true
        super.init()
    }
    
    override func request(with request: ImageHandler.Request) {
        request_withBaseRequest.incrementMethodCount()
        request_withBaseRequest.addParameters(request)
        super.request(with: request)
    }
    
    override func requestRemotely(with request: ImageHandler.WebRequest) {
        request_withWebRequest.incrementMethodCount()
        request_withWebRequest.addParameters(request)
        
        if (fetchActualData) {
            super.requestRemotely(with: request)
        }
    }
    
    override func requestLocally(with request: ImageHandler.LocalRequest) {
        request_withLocalRequest.incrementMethodCount()
        request_withLocalRequest.addParameters(request)
        
        if fetchActualData {
            super.requestLocally(with: request)
        }
    }
    
    override func rxRequest(with request: ImageHandler.Request)
        -> Observable<UIImage>
    {
        rxRequest_withBaseRequest.incrementMethodCount()
        rxRequest_withBaseRequest.addParameters(request)
        return super.rxRequest(with: request)
    }
}

extension TestImageHandler: FakeProtocol {
    func reset() {
        [
            request_withBaseRequest,
            request_withLocalRequest,
            request_withBaseRequest,
            rxRequest_withBaseRequest
        ].forEach({$0.reset()})
    }
}
