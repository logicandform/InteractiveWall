//  Copyright © 2018 slant. All rights reserved.

import Foundation
import UIKit

enum Discipline: String {
    case school = "School"
    case event = "Event"
    case hearing = "Hearing"

    init?(from stringValue: String) {
        if let discipline = Discipline(rawValue: stringValue) {
            self = discipline
        } else {
            return nil
        }
    }

    var color: UIColor {
        switch self {
        case .school:
            return .blue
        case .event:
            return .yellow
        case .hearing:
            return .red
        }
    }
}
