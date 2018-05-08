//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum LetterGroup: SearchItemDisplayable {

    case abcd
    case efgh
    case ijkl
    case mnop
    case qrstu
    case vwxyz

    var title: String {
        switch self {
        case .abcd:
            return "A-D"
        case .efgh:
            return "E-H"
        case .ijkl:
            return "I-L"
        case .mnop:
            return "M-P"
        case .qrstu:
            return "Q-U"
        case .vwxyz:
            return "V-Z"
        }
    }

    static var allValues: [LetterGroup] {
        return [.abcd, .efgh, .ijkl, .mnop, .qrstu, .vwxyz]
    }
}
