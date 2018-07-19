//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineDate {
    var day: CGFloat?
    var month: Int?
    var year: Int?

    private struct Keys {
        static let day = "day"
        static let month = "month"
        static let year = "year"
    }

    var toJSON: [String: Any] {
        return [Keys.day: day as Any, Keys.month: month as Any, Keys.year: year as Any]
    }


    // MARK: Init

    init() {}

    init(day: CGFloat?, month: Int?, year: Int?) {
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
