//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum Month: Int {
    case january
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december

    init?(abbreviation: String) {
        switch abbreviation {
        case "JAN":
            self = .january
        case "FEB":
            self = .february
        case "MAR":
            self = .march
        case "APR":
            self = .april
        case "MAY":
            self = .may
        case "JUN":
            self = .june
        case "JUL":
            self = .july
        case "AUG":
            self = .august
        case "SEP":
            self = .september
        case "OCT":
            self = .october
        case "NOV":
            self = .november
        case "DEC":
            self = .december
        default:
            return nil
        }
    }

    init?(name: String) {
        switch name.lowercased() {
        case "january":
            self = .january
        case "february":
            self = .february
        case "march":
            self = .march
        case "april":
            self = .april
        case "may":
            self = .may
        case "june":
            self = .june
        case "july":
            self = .july
        case "august":
            self = .august
        case "september":
            self = .september
        case "october":
            self = .october
        case "november":
            self = .november
        case "december":
            self = .december
        default:
            return nil
        }
    }

    var abbreviation: String {
        switch self {
        case .january:
            return "JAN"
        case .february:
            return "FEB"
        case .march:
            return "MAR"
        case .april:
            return "APR"
        case .may:
            return "MAY"
        case .june:
            return "JUN"
        case .july:
            return "JUL"
        case .august:
            return "AUG"
        case .september:
            return "SEP"
        case .october:
            return "OCT"
        case .november:
            return "NOV"
        case .december:
            return "DEC"
        }
    }

    static var allValues: [Month] {
        return [.january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december]
    }
}
