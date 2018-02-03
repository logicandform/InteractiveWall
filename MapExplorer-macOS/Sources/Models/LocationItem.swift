//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit

class LocationItem {
    let title: String?
    let locationName: String
    let discipline: Discipline
    let coordinate: CLLocationCoordinate2D

    init(title: String?, name: String, coordinate: CLLocationCoordinate2D, discipline: Discipline) {
        self.title = title
        self.locationName = name
        self.coordinate = coordinate
        self.discipline = discipline
    }

    init?(fromJSON json: [String: Any]) {
        guard let name = json["placeName"] as? String,
            let type = json["type"] as? String,
            let discipline = Discipline(from: type),
            let latitudeString = json["latitude"] as? String,
            let longitudeString = json["longitude"] as? String else {
                return nil
        }
        self.title = json["title"] as? String
        self.locationName = name
        self.discipline = discipline
        let latitude = Double(LocationItem.matches(for: "\\d+(\\.\\d+)?", in: latitudeString)[0])!
        let longitude = Double(LocationItem.matches(for: "\\d+(\\.\\d+)?", in: longitudeString)[0])! * (-1)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
