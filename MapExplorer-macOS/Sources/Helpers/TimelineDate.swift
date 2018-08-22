//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineDate: CustomStringConvertible, Comparable {
    let day: CGFloat
    let month: Int
    var year: Int
    let defaultDayUsed: Bool
    let defaultMonthUsed: Bool

    var description: String {
        if defaultMonthUsed {
            return "\(year)"
        } else if defaultDayUsed {
            let m = Month(rawValue: month) ?? .january
            return "\(m.title), \(year)"
        }

        let m = Month(rawValue: month) ?? .january
        let d = max(Int(day * 31), 1)
        return "\(m.title) \(d), \(year)"
    }

    var toJSON: JSON {
        return [Keys.day: day, Keys.month: month, Keys.year: year]
    }

    private struct Keys {
        static let day = "day"
        static let month = "month"
        static let year = "year"
    }

    private struct Constants {
        static let defaultDay: CGFloat = 0
        static let defaultMonth = 0
    }


    // MARK: Init

    init(day: CGFloat?, month: Int?, year: Int) {
        self.day = day ?? Constants.defaultDay
        self.month = month ?? Constants.defaultMonth
        self.year = year
        self.defaultDayUsed = day == nil ? true : false
        self.defaultMonthUsed = month == nil ? true : false
    }

    init(date: (day: CGFloat, month: Int, year: Int)) {
        self.day = date.day
        self.month = date.month
        self.year = date.year
        self.defaultDayUsed = false
        self.defaultMonthUsed = false
    }

    init?(json: JSON) {
        guard let day = json["day"] as? CGFloat, let month = json["month"] as? Int, let year = json["year"] as? Int else {
            return nil
        }
        self.day = day
        self.month = month
        self.year = year
        self.defaultDayUsed = false
        self.defaultMonthUsed = false
    }

    public static func < (lhs: TimelineDate, rhs: TimelineDate) -> Bool {
        if lhs.year == rhs.year {
            if lhs.month == rhs.month {
                return lhs.day < rhs.day
            }
            return lhs.month < rhs.month
        }
        return lhs.year < rhs.year
    }
}
