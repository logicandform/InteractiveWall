//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class Dates {
    var startDay: CGFloat?
    var startMonth: Int?
    var startYear: Int?
    var endDay: CGFloat?
    var endMonth: Int?
    var endYear: Int?
    private let years = Array(style.firstYear...style.lastYear)

    private struct Constants {
        let monthLength = 31
        let startEndTransition = "-"
    }


    // MARK: Init

    init(date: String) {
        if date.isEmpty {
            return
        }

//        - ,
        let dateArray = date.componentsSeparatedByStrings(separators: ["-", ","])
//        let dateArray = date.flatMap({ $0.components(separatedBy: "-") })
        for date in dateArray {
            if startYear != nil, let endYear = Int(date), years.contains(endYear) {
                self.endYear = endYear
            } else if let startYear = Int(date), years.contains(startYear) {
                self.startYear = startYear
            }
        }

        if endYear == nil {
            endYear = startYear
        }
        let test = 3
    }


    // MARK: Helpers

    
}
