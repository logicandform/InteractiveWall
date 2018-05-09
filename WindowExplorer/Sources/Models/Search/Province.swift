//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum Province: SearchItemDisplayable {
    case britishColumbia
    case alberta
    case manitoba
    case ontario
    case quebec
    case saskatchewan
    case newfoundland
    case novaScotia
    case newBrunswick
    case princeEdwardIsland
    case yukonTerritory
    case northwestTerritory
    case nunavut

    var title: String {
        switch self {
        case .britishColumbia:
            return "British Columbia"
        case .alberta:
            return "Alberta"
        case .manitoba:
            return "Manitoba"
        case .ontario:
            return "Ontario"
        case .quebec:
            return "Quebec"
        case .saskatchewan:
            return "Saskatchewan"
        case .newfoundland:
            return "Newfoundland & Labrador"
        case .novaScotia:
            return "Nova Scotia"
        case .newBrunswick:
            return "New Brunswick"
        case .princeEdwardIsland:
            return "Prince Edward Island"
        case .yukonTerritory:
            return "Yukon Territory"
        case .northwestTerritory:
            return "Northwest Territory"
        case .nunavut:
            return "Nunavut"
        }
    }

    static var allValues: [Province] {
        return [.alberta, .britishColumbia, .manitoba, .newBrunswick, .newfoundland, .northwestTerritory, .novaScotia, .nunavut, .ontario, .princeEdwardIsland, .quebec, .saskatchewan, .yukonTerritory]
    }
}
