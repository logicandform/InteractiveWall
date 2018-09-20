//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ApplicationState {
    case running
    case stopped

    var title: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        }
    }

    var color: NSColor {
        switch self {
        case .running:
            return .green
        case .stopped:
            return .red
        }
    }
}
