//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineDate {
    var day: CGFloat = Constants.defaultDay
    var month: Int = Constants.defaultMonth
    var year: Int = Constants.defaultYear

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
        static let defaultYear = 1880
    }


    // MARK: Init

    init() {}

    init(day: CGFloat, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
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
