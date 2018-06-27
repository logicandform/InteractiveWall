//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class TimelineEvent: Hashable {

    let title: String
    let start: Int
    let end: Int

    var hashValue: Int {
        return start ^ end ^ title.hashValue
    }

    private struct Keys {
        static let locations = "locations"
        static let title = "locationName"
        static let start = "start"
        static let end = "end"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let startString = json[Keys.start] as? String, let endString = json[Keys.end] as? String, let start = Int(startString), let end = Int(endString) else {
            return nil
        }

        self.title = title
        self.start = start
        self.end = end
    }

    init(title: String, start: Int, end: Int) {
        self.title = title
        self.start = start
        self.end = end
    }

    static func allEvents() -> [TimelineEvent] {
        guard let file = Bundle.main.url(forResource: "vhec_map_points", withExtension: "json"), let data = try? Data(contentsOf: file), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON, let result = json, let locations = result[Keys.locations] as? [JSON] else {
            return []
        }

        return locations.compactMap { TimelineEvent(json: $0) }
    }

    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.title == rhs.title && lhs.start == rhs.start && lhs.end == rhs.end
    }
}
