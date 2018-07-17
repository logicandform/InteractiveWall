//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineDate {
    var day: CGFloat
    var month: Int
    var year: Int

    private struct Keys {
        static let day = "day"
        static let month = "month"
        static let year = "year"
    }

    var toJSON: [String: Any] {
        return [Keys.day: day, Keys.month: month, Keys.year: year]
    }


    // MARK: Init

    init(day: CGFloat, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
    }

    init?(json: JSON) {
        if let day = json["day"] as? CGFloat, let month = json["month"] as? Int, let year = json["year"] as? Int {
            self.day = day
            self.month = month
            self.year = year
        } else {
            self.day = 0
            self.month = 0
            self.year = 0
        }
    }
}
