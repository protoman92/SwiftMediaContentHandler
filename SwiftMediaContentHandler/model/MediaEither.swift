//
//  MediaEither.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities

public typealias MediaError = Exception

public typealias LMTEither = Either<MediaError,LocalMediaType>

public typealias AlbumEither = Either<MediaError,AlbumType>
