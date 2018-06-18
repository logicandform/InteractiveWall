//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum ApplicationType {
    case mapExplorer
    case timeline
    case nodeNetwork

    var path: String {
        switch self {
        case .mapExplorer, .timeline:
            return Paths.mapExplorer
        case .nodeNetwork:
            return ""
        }
    }
}
