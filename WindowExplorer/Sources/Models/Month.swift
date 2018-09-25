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
        switch abbreviation.lowercased() {
        case "jan":
            self = .january
        case "feb":
            self = .february
        case "mar":
            self = .march
        case "apr":
            self = .april
        case "may":
            self = .may
        case "jun":
            self = .june
        case "jul":
            self = .july
        case "aug":
            self = .august
        case "sep":
            self = .september
        case "oct":
            self = .october
        case "nov":
            self = .november
        case "dec":
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

    var title: String {
        switch self {
        case .january:
            return "January"
        case .february:
            return "February"
        case .march:
            return "March"
        case .april:
            return "April"
        case .may:
            return "May"
        case .june:
            return "June"
        case .july:
            return "July"
        case .august:
            return "August"
        case .september:
            return "September"
        case .october:
            return "October"
        case .november:
            return "November"
        case .december:
            return "December"
        }
    }

    var abbreviatedTitle: String {
        switch self {
        case .january:
            return "Jan"
        case .february:
            return "Feb"
        case .march:
            return "March"
        case .april:
            return "April"
        case .may:
            return "May"
        case .june:
            return "June"
        case .july:
            return "July"
        case .august:
            return "Aug"
        case .september:
            return "Sept"
        case .october:
            return "Oct"
        case .november:
            return "Nov"
        case .december:
            return "Dec"
        }
    }

    static var allValues: [Month] {
        return [.january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december]
    }
}
