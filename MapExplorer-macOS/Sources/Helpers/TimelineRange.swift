//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


/// Class containing a start and end date for Timeline items, as well as the ability to parse dates from a string
struct TimelineRange: CustomStringConvertible, Equatable {
    var startDate: TimelineDate
    var endDate: TimelineDate

    var description: String {
        return "\(startDate) - \(endDate)"
    }

    private struct Constants {
        static let minimumYear = 32
        static let maximumDay = 30
        static let days = Array(1...31)
        static let months = Array(1...12)
    }


    // MARK: Init

    init?(_ date: String?) {
        guard let date = date, !date.isEmpty else {
            return nil
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,./")
        if dateArray.contains(where: { !$0.isNumerical }), let dates = TimelineRange.parseNonNumerical(dateArray: dateArray) {
            self.startDate = dates.startDate
            self.endDate = dates.endDate
        } else if let dates = TimelineRange.parseNumerical(dateArray: dateArray) {
            self.startDate = dates.startDate
            self.endDate = dates.endDate
        } else {
            return nil
        }
    }


    // MARK: Helpers

    private static func parseNumerical(dateArray: [String]) -> (startDate: TimelineDate, endDate: TimelineDate)? {
        var start: TimelineDate? = nil
        var end: TimelineDate? = nil
        var startDay: CGFloat? = nil
        var endDay: CGFloat? = nil
        var startMonth: Int? = nil
        var endMonth: Int? = nil
        var startYear: Int? = nil
        var endYear: Int? = nil
        for date in dateArray {
            if let numericalDate = Int(date) {
                if startDay == nil, Constants.days.contains(numericalDate) {
                    startDay = CGFloat(numericalDate - 1) / CGFloat(Constants.maximumDay)
                } else if startMonth == nil, Constants.months.contains(numericalDate) {
                    startMonth = numericalDate - 1
                } else if startYear == nil, numericalDate > Constants.minimumYear {
                    startYear = numericalDate
                } else if endDay == nil, Constants.days.contains(numericalDate) {
                    endDay = CGFloat(numericalDate - 1) / CGFloat(Constants.maximumDay)
                } else if endMonth == nil, Constants.months.contains(numericalDate) {
                    endMonth = numericalDate - 1
                } else if endYear == nil, numericalDate > Constants.minimumYear {
                    endYear = numericalDate
                }
            }
        }

        if let day = startDay, endDay == nil {
            endDay = day
        }
        if let month = startMonth, endMonth == nil {
            endMonth = month
        }
        if let year = startYear, endYear == nil {
            endYear = year
        }

        if let year = startYear {
            start = TimelineDate(day: startDay, month: startMonth, year: year)
        }
        if let year = endYear {
            end = TimelineDate(day: endDay, month: endMonth, year: year)
        } else if let year = startYear {
            end = TimelineDate(day: endDay, month: endMonth, year: year)
        }

        if let start = start, let end = end {
            return (startDate: start, endDate: end)
        } else {
            return nil
        }
    }

    private static func parseNonNumerical(dateArray: [String]) -> (startDate: TimelineDate, endDate: TimelineDate)? {
        var start: TimelineDate? = nil
        var end: TimelineDate? = nil
        var startDay: CGFloat? = nil
        var endDay: CGFloat? = nil
        var startMonth: Int? = nil
        var endMonth: Int? = nil
        var startYear: Int? = nil
        var endYear: Int? = nil
        for date in dateArray {
            if let year = Int(date), year > Constants.minimumYear {
                if startYear == nil {
                    startYear = year
                } else {
                    endYear = year
                }
            }

            if let day = Int(date), Constants.days.contains(day) {
                if startDay == nil {
                    startDay = CGFloat(day - 1) / CGFloat(Constants.maximumDay)
                } else {
                    endDay = CGFloat(day - 1) / CGFloat(Constants.maximumDay)
                }
            } else if let day = Int(date.digitsInString), Constants.days.contains(day) {
                if startDay == nil {
                    startDay = CGFloat(day - 1) / CGFloat(Constants.maximumDay)
                } else {
                    endDay = CGFloat(day - 1) / CGFloat(Constants.maximumDay)
                }
            }

            if let month = Month(name: date) {
                if startMonth == nil {
                    startMonth = month.rawValue
                } else {
                    endMonth = month.rawValue
                }
            } else if let month = Month(abbreviation: date) {
                if startMonth == nil {
                    startMonth = month.rawValue
                } else {
                    endMonth = month.rawValue
                }
            }
        }

        if let day = startDay, endDay == nil {
            endDay = day
        }
        if let month = startMonth, endMonth == nil {
            endMonth = month
        }
        if let year = startYear, endYear == nil {
            endYear = year
        }

        if let year = startYear {
            start = TimelineDate(day: startDay, month: startMonth, year: year)
        }
        if let year = endYear {
            end = TimelineDate(day: endDay, month: endMonth, year: year)
        } else if let year = startYear {
            end = TimelineDate(day: endDay, month: endMonth, year: year)
        }

        if let start = start, let end = end {
            return (startDate: start, endDate: end)
        } else {
            return nil
        }
    }

    static func == (lhs: TimelineRange, rhs: TimelineRange) -> Bool {
        return lhs.startDate.day == rhs.startDate.day && lhs.startDate.month == rhs.startDate.month && lhs.startDate.year == rhs.startDate.year && lhs.endDate.day == rhs.endDate.day && lhs.endDate.month == rhs.endDate.month && lhs.endDate.year == rhs.endDate.year
    }
}
