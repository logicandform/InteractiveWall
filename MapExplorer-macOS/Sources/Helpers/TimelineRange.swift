//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


/// Class containing a start and end date for Timeline items, as well as the ability to parse dates from a string
class TimelineRange {
    var startDate: TimelineDate
    var endDate: TimelineDate

    private struct Constants {
        static let minimumYear = 100
        static let maximumDay = 31
        static let days = Array(1...31)
        static let months = Array(1...12)
    }


    // MARK: Init

    init(_ date: String) {
        startDate = TimelineDate()
        endDate = TimelineDate()
        if date.isEmpty {
            return
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,./")
        if dateArray.first(where: { !$0.isNumerical }) == nil {
            parseNumerical(dateArray: dateArray)
        } else {
            parseNonNumerical(dateArray: dateArray)
        }
    }


    // MARK: Helpers

    private func parseNumerical(dateArray: [String]) {
        var startDay: CGFloat? = nil
        var endDay: CGFloat? = nil
        var startMonth: Int? = nil
        var endMonth: Int? = nil
        var startYear: Int? = nil
        var endYear: Int? = nil
        for date in dateArray {
            if let numericalDate = Int(date) {
                if startDay == nil, Constants.days.contains(numericalDate) {
                    startDay = CGFloat(numericalDate) / CGFloat(Constants.maximumDay)
                } else if startMonth == nil, Constants.months.contains(numericalDate) {
                    startMonth = numericalDate - 1
                } else if startYear == nil, numericalDate > Constants.minimumYear {
                    startYear = numericalDate
                } else if endDay == nil, Constants.days.contains(numericalDate) {
                    endDay = CGFloat(numericalDate) / CGFloat(Constants.maximumDay)
                } else if endMonth == nil, Constants.months.contains(numericalDate) {
                    endMonth = numericalDate - 1
                } else if endYear == nil, numericalDate > Constants.minimumYear {
                    endYear = numericalDate
                }
            }
        }

        if let day = startDay {
            startDate.day = day
        }
        if let month = startMonth {
            startDate.month = month
        }
        if let year = startYear {
            startDate.year = year
        }
        if let day = endDay {
            endDate.day = day
        } else if let day = startDay {
            endDate.day = day
        }
        if let month = endMonth {
            endDate.month = month
        } else if let month = startMonth {
            endDate.month = month
        }
        if let year = endYear {
            endDate.year = year
        } else if let year = startYear {
            endDate.year = year
        }
    }

    private func parseNonNumerical(dateArray: [String]) {
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
                    startDay = CGFloat(day) / CGFloat(Constants.maximumDay)
                } else {
                    endDay = CGFloat(day) / CGFloat(Constants.maximumDay)
                }
            } else if let day = Int(date.digitsInString), Constants.days.contains(day) {
                if startDay == nil {
                    startDay = CGFloat(day) / CGFloat(Constants.maximumDay)
                } else {
                    endDay = CGFloat(day) / CGFloat(Constants.maximumDay)
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

        if let day = startDay {
            startDate.day = day
        }
        if let month = startMonth {
            startDate.month = month
        }
        if let year = startYear {
            startDate.year = year
        }
        if let day = endDay {
            endDate.day = day
        } else if let day = startDay {
            endDate.day = day
        }
        if let month = endMonth {
            endDate.month = month
        } else if let month = startMonth {
            endDate.month = month
        }
        if let year = endYear {
            endDate.year = year
        } else if let year = startYear {
            endDate.year = year
        }
    }
}
