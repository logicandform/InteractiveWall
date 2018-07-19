//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineRange {
    var startDate: TimelineDate
    var endDate: TimelineDate
    private let minimumYear = 100
    private let minimumDay = 31
    private let days = Array(1...31)


    // MARK: Init

    init(_ date: String) {
        startDate = TimelineDate()
        endDate = TimelineDate()
        if date.isEmpty {
            return
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,")
        for date in dateArray {
            if let year = Int(date), year > minimumYear {
                if startDate.year == nil {
                    startDate.year = year
                } else {
                    endDate.year = year
                }
            }

            if let day = Int(date), days.contains(day) {
                if startDate.day == nil {
                    startDate.day = CGFloat(day / minimumDay)
                } else {
                    endDate.day = CGFloat(day / minimumDay)
                }
            }

            if let month = Month(name: date) {
                if startDate.month == nil {
                    startDate.month = month.rawValue
                } else {
                    endDate.month = month.rawValue
                }
            }
        }

        if endDate.year == nil {
            endDate.year = startDate.year
        }
        if endDate.month == nil {
            endDate.month = startDate.month
        }
        if endDate.day == nil {
            endDate.day = startDate.day
        }
    }
}
