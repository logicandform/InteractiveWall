//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ApplicationType: String {
    case mapExplorer
    case timeline
    case nodeNetwork

    func controller() -> NSViewController {
        switch self {
        case .mapExplorer:
            return MapViewController.instance()
        case .timeline:
            return TimelineViewController.instance()
        case .nodeNetwork:
            return NSViewController()
        }
    }
}
