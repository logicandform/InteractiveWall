//  Copyright © 2018 slant. All rights reserved.

import Foundation
import AppKit

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
}
