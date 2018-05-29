//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum Province {
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

    init?(abbreviation: String) {
        switch abbreviation {
        case "BC":
            self = .britishColumbia
        case "AB":
            self = .alberta
        case "MB":
            self = .manitoba
        case "ON":
            self = .ontario
        case "QC":
            self = .quebec
        case "SK":
            self = .ontario
        case "NL":
            self = .newfoundland
        case "NS":
            self = .novaScotia
        case "NB":
            self = .newBrunswick
        case "PE":
            self = .princeEdwardIsland
        case "YT":
            self = .yukonTerritory
        case "NT":
            self = .northwestTerritory
        case "NU":
            self = .nunavut
        default:
            return nil
        }
    }

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

    var abbreviation: String {
        switch self {
        case .britishColumbia:
            return "BC"
        case .alberta:
            return "AB"
        case .manitoba:
            return "MB"
        case .ontario:
            return "ON"
        case .quebec:
            return "QC"
        case .saskatchewan:
            return "SK"
        case .newfoundland:
            return "NL"
        case .novaScotia:
            return "NS"
        case .newBrunswick:
            return "NB"
        case .princeEdwardIsland:
            return "PE"
        case .yukonTerritory:
            return "YT"
        case .northwestTerritory:
            return "NT"
        case .nunavut:
            return "NU"
        }
    }

    static var allValues: [Province] {
        return [.alberta, .britishColumbia, .manitoba, .newBrunswick, .newfoundland, .northwestTerritory, .novaScotia, .nunavut, .ontario, .princeEdwardIsland, .quebec, .saskatchewan, .yukonTerritory]
    }
}
