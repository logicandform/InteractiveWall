//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineDate: CustomStringConvertible {
    let day: CGFloat
    let month: Int
    let year: Int

    var description: String {
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
    }

    init(date: (day: CGFloat, month: Int, year: Int)) {
        self.day = date.day
        self.month = date.month
        self.year = date.year
    }

    init?(json: JSON) {
        guard let day = json["day"] as? CGFloat, let month = json["month"] as? Int, let year = json["year"] as? Int else {
            return nil
        }
        self.day = day
        self.month = month
        self.year = year
    }
}
