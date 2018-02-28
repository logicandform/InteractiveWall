//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum EntityType {
    case individual
    case government
    case unknown(String)

    var description: String {
        switch self {
        case .individual:
            return "Individual"
        case .government:
            return "Government Agency"
        case .unknown(let name):
            return name
        }
    }

    static func from(_ string: String?) -> EntityType? {
        guard let value = string else {
            return nil
        }

        switch value {
        case "Individual":
            return .individual
        case "Government Agency":
            return .government
        default:
            return .unknown(value)
        }
    }
}
