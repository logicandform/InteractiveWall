//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


enum CollectionType {
    case map
    case timeline
    case topic
    case singular
    case testimony

    init?(string: String?) {
        switch string?.lowercased() {
        case "map":
            self = .map
        case "timeline":
            self = .timeline
        case "themes":
            self = .topic
        case "stand-alone":
            self = .singular
        case "survivors speak":
            self = .testimony
        default:
            return nil
        }
    }
}


final class RecordCollection: Record {

    let collectionType: CollectionType?


    private struct Keys {
        static let presentation = "presentationType"
    }


    // MARK: Init

    init?(json: JSON) {
        collectionType = CollectionType(string: json[Keys.presentation] as? String)
        super.init(type: .collection, json: json)
    }
}
