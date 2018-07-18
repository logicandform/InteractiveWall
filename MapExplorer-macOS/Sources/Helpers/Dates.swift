//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class Dates {
    var startDay: Int?
    var startMonth: Month?
    var startYear: Int?
    var endDay: Int?
    var endMonth: Month?
    var endYear: Int?
    private let years = Array(style.firstYear...2018)
    private let days = Array(1...31)

    private struct Constants {
        let monthLength = 31
        let startEndTransition = "-"
    }


    // MARK: Init

    init(_ date: String) {
        if date.isEmpty {
            return
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,")
        for date in dateArray {
            if let year = Int(date), years.contains(year) {
                if startYear == nil {
                    self.startYear = year
                } else {
                    self.endYear = year
                }
            }

            if let day = Int(date), days.contains(day) {
                if startDay == nil {
                    self.startDay = day
                } else {
                    self.endDay = day
                }
            }

            if let month = Month(name: date) {
                if startMonth == nil {
                    self.startMonth = month
                } else {
                    self.endMonth = month
                }
            }
        }

        if endYear == nil {
            endYear = startYear
        }
        if endMonth == nil {
            endMonth = startMonth
        }
        if endDay == nil {
            endDay = startDay
        }
    }
}
