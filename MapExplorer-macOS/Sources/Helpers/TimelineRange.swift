//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineRange {
    var startDate: TimelineDate
    var endDate: TimelineDate
    private let minimumYear = 100
    private let maximumDay = 31
    private let days = Array(1...31)
    private let months = Array(1...12)


    // MARK: Init

    init(_ date: String) {
        startDate = TimelineDate()
        endDate = TimelineDate()
        if date.isEmpty {
            return
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,.")
        if dateArray.first(where: { !$0.isNumerical }) == nil {
            parseNumerical(dateArray: dateArray)
        } else {
            parseNonNumerical(dateArray: dateArray)
        }
    }


    // MARK: Helpers

    private func parseNumerical(dateArray: [String]) {
        for date in dateArray {
            if let numericalDate = Int(date) {

                if startDate.day == nil, days.contains(numericalDate) {
                    startDate.day = CGFloat(numericalDate) / CGFloat(maximumDay)
                } else if startDate.month == nil, months.contains(numericalDate) {
                    startDate.month = numericalDate - 1
                } else if startDate.year == nil, numericalDate > minimumYear {
                    startDate.year = numericalDate
                } else if endDate.day == nil, days.contains(numericalDate) {
                    endDate.day = CGFloat(numericalDate) / CGFloat(maximumDay)
                } else if endDate.month == nil, months.contains(numericalDate) {
                    endDate.month = numericalDate - 1
                } else if endDate.year == nil, numericalDate > minimumYear {
                    endDate.year = numericalDate
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

    private func parseNonNumerical(dateArray: [String]) {
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
                    startDate.day = CGFloat(day) / CGFloat(maximumDay)
                } else {
                    endDate.day = CGFloat(day) / CGFloat(maximumDay)
                }
            }

            if let month = Month(name: date) {
                if startDate.month == nil {
                    startDate.month = month.rawValue
                } else {
                    endDate.month = month.rawValue
                }
            } else if let month = Month(abbreviation: date) {
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
