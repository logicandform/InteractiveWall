//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TimelineType {
    case month
    case year
    case decade
    case century

    var sectionWidth: Int {
        switch self {
        case .month:
            return 1920
        case .year:
            return 1920
        case .decade:
            return 192
        case .century:
            return 32
        }
    }

    var itemWidth: Int {
        switch self {
        case .month:
            return 240
        case .year:
            return 240
        case .decade:
            return 192
        case .century:
            return 32
        }
    }

    var infiniteBuffer: Int {
        switch self {
        case .month:
            return 2
        case .year:
            return 2
        case .decade:
            return 11
        case .century:
            return 0
        }
    }
}
