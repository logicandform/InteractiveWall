//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum ApplicationType {
    case mapExplorer
    case timeline

    var path: String {
        switch self {
        case .mapExplorer:
            return Paths.mapExplorer
        case .timeline:
            return ""
        }
    }
}
