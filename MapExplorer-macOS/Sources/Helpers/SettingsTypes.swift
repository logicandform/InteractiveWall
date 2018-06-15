//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingsTypes: Int {
    case showLabels = 50
    case showMiniMap = 51
    case toggleSchools = 52
    case toggleEvents = 53
    case toggleOrganizations = 54
    case toggleArtifacts = 55

    var recordType: RecordType? {
        switch self {
        case .toggleSchools:
            return RecordType.school
        case .toggleEvents:
            return RecordType.event
        case .toggleOrganizations:
            return nil
        case .toggleArtifacts:
            return nil
        case .showLabels:
            return nil
        case .showMiniMap:
            return nil
        }
    }
}
