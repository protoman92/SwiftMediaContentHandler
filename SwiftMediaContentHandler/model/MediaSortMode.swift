//
//  MediaSortMode.swift
//  SwiftMediaContentHandler
//
//  Created by Hai Pham on 6/26/17.
//  Copyright © 2017 Swiften. All rights reserved.
//

import SwiftUtilities

/// Provide the sort mode.
///
/// - creationDate: Sort by creationDate.
public enum MediaSortMode {
    case creationDate
}

extension MediaSortMode: SortModeType {
    
    /// Get the associated sort key String.
    public var sortKey: String {
        switch self {
        case .creationDate:
            return "creationDate"
        }
    }
}
