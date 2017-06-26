//
//  MediaEither.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import Result
import SwiftUtilities

public typealias MediaError = Exception

public typealias LMTResult = Result<LocalMediaType,MediaError>

public typealias AlbumResult = Result<AlbumType,MediaError>
