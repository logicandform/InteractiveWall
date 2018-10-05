//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class TimelineEvent: Hashable {

    let id: Int
    let type: RecordType
    let title: String
    let thumbnail: URL?
    let localThumbnail: URL?
    var dates: DateRange
    var highlighted = false

    var hashValue: Int {
        return dates.startDate.year ^ type.hashValue ^ title.hashValue
    }

    private struct Keys {
        static let locations = "locations"
        static let title = "locationName"
        static let start = "start"
        static let end = "end"
    }


    // MARK: Init

    init(id: Int, type: RecordType, title: String, dates: DateRange, thumbnail: URL?, localThumbnail: URL?) {
        self.id = id
        self.type = type
        self.title = title
        self.dates = dates
        self.thumbnail = thumbnail
        self.localThumbnail = localThumbnail
    }


    // MARK: Static

    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.title == rhs.title && lhs.type == rhs.type && lhs.id == rhs.id && lhs.dates == rhs.dates
    }
}
