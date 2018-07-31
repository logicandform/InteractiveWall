//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class TimelineEvent: Hashable {
    let id: Int
    let type: RecordType
    let title: String
    let dates: TimelineRange

    var hashValue: Int {
        return dates.startDate.year ^ dates.endDate.year ^ title.hashValue
    }

    private struct Keys {
        static let locations = "locations"
        static let title = "locationName"
        static let start = "start"
        static let end = "end"
    }


    // MARK: Init

    init(id: Int, type: RecordType, title: String, dates: TimelineRange) {
        self.id = id
        self.type = type
        self.title = title
        self.dates = dates
    }

    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.title == rhs.title && lhs.dates.startDate.day == rhs.dates.startDate.day && lhs.dates.startDate.month == rhs.dates.startDate.month && lhs.dates.startDate.year == rhs.dates.startDate.year && lhs.dates.endDate.day == rhs.dates.endDate.day && lhs.dates.endDate.month == rhs.dates.endDate.month && lhs.dates.endDate.year == rhs.dates.endDate.year
    }
}
