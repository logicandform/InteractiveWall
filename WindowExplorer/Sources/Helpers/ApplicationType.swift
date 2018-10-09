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
            return Paths.nodeNetwork
        }
    }

    var appName: String {
        switch self {
        case .mapExplorer, .timeline:
            return "MapExplorer"
        case .nodeNetwork:
            return "NodeExplorer"
        }
    }

    func port(app: Int) -> String {
        switch self {
        case .mapExplorer, .timeline:
            return "AppListener\(app)"
        case .nodeNetwork:
            return "NodeExplorer"
        }
    }
}
