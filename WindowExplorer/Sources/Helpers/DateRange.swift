//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct DateRange: Equatable {
    var startDate: RecordDate
    var endDate: RecordDate?

    private struct Constants {
        static let minimumYear = 1000
        static let maximumDay = 31
        static let days = Array(1...31)
        static let months = Array(1...12)
    }


    // MARK: Init

    init?(from date: String?) {
        guard let date = date, !date.isEmpty else {
            return nil
        }

        let dateArray = date.componentsSeparatedBy(separators: " -,./")
        if dateArray.contains(where: { !$0.isNumerical }), let dates = DateRange.parseNonNumerical(dateArray: dateArray) {
            self.startDate = dates.startDate
            self.endDate = dates.endDate
        } else if let dates = DateRange.parseNumerical(dateArray: dateArray) {
            self.startDate = dates.startDate
            self.endDate = dates.endDate
        } else {
            return nil
        }
    }


    // MARK: API

    func description(small: Bool) -> String {
        if let endDate = endDate {
            return "\(startDate.description(small: small)) - \(endDate.description(small: small))"
        } else {
            return "\(startDate.description(small: small))"
        }
    }


    // MARK: Helpers

    private static func parseNumerical(dateArray: [String]) -> (startDate: RecordDate, endDate: RecordDate?)? {
        var start: RecordDate? = nil
        var end: RecordDate? = nil
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

        if endDay == nil && endMonth == nil && endYear == nil {
            if let year = startYear {
                return (startDate: RecordDate(day: startDay, month: startMonth, year: year), endDate: nil)
            } else {
                return nil
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
            start = RecordDate(day: startDay, month: startMonth, year: year)
        }
        if let year = endYear {
            end = RecordDate(day: endDay, month: endMonth, year: year)
        } else if let year = startYear {
            end = RecordDate(day: endDay, month: endMonth, year: year)
        }

        if let start = start, let end = end {
            return (startDate: start, endDate: end)
        } else {
            return nil
        }
    }

    private static func parseNonNumerical(dateArray: [String]) -> (startDate: RecordDate, endDate: RecordDate?)? {
        var start: RecordDate? = nil
        var end: RecordDate? = nil
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

        if endDay == nil && endMonth == nil && endYear == nil {
            if let year = startYear {
                return (startDate: RecordDate(day: startDay, month: startMonth, year: year), endDate: nil)
            } else {
                return nil
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
            start = RecordDate(day: startDay, month: startMonth, year: year)
        }
        if let year = endYear {
            end = RecordDate(day: endDay, month: endMonth, year: year)
        } else if let year = startYear {
            end = RecordDate(day: endDay, month: endMonth, year: year)
        }

        if let start = start, let end = end {
            return (startDate: start, endDate: end)
        } else {
            return nil
        }
    }

    static func == (lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate.day == rhs.startDate.day && lhs.startDate.month == rhs.startDate.month && lhs.startDate.year == rhs.startDate.year && lhs.endDate?.day == rhs.endDate?.day && lhs.endDate?.month == rhs.endDate?.month && lhs.endDate?.year == rhs.endDate?.year
    }
}
