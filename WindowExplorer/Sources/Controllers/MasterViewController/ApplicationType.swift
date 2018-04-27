//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum ApplicationType {
    case mapExplorer

    var path: String {
        switch self {
        case .mapExplorer:
            return Paths.mapExplorer
        }
    }
}
