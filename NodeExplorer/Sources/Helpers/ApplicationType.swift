//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum ApplicationType: String {
    case mapExplorer
    case timeline
    case nodeNetwork

    func port(app: Int) -> String {
        switch self {
        case .mapExplorer, .timeline:
            return "AppListener\(app)"
        case .nodeNetwork:
            return "NodeExplorer"
        }
    }
}
