//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum ApplicationType: String {
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
