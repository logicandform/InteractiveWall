//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum LetterGroup: String, SearchItemDisplayable {

    case abc
    case def
    case ghi
    case jkl
    case mno
    case pqr
    case stuv
    case wxyz

    var title: String {
        switch self {
        case .abc:
            return "A-C"
        case .def:
            return "D-F"
        case .ghi:
            return "G-I"
        case .jkl:
            return "J-L"
        case .mno:
            return "M-O"
        case .pqr:
            return "P-R"
        case .stuv:
            return "S-V"
        case .wxyz:
            return "W-Z"
        }
    }

    static var allValues: [LetterGroup] {
        return [.abc, .def, .ghi, .jkl, .mno, .pqr, .stuv, .wxyz]
    }
}
