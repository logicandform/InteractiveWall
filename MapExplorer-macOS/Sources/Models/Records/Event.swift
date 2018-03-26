//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class Event: Record {

    let id: Int
    let type = RecordType.event
    let title: String
    let coordinate: CLLocationCoordinate2D

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let coordinate = "coordinate"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String, let coordinate = CLLocationCoordinate2D(string: json[Keys.coordinate] as? String) else {
            return nil
        }

        self.id = id
        self.title = title
        self.coordinate = coordinate
    }
}
