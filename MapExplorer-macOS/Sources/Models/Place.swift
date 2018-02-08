//  Copyright © 2018 slant. All rights reserved.

import MapKit

class Place: MKPointAnnotation {

    let discipline: Discipline

    private struct Keys {
        static let subtitle = "placeName"
        static let type = "type"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let title = "title"
    }


    // MARK: Init

    init(title: String?, subtitle: String, coordinate: CLLocationCoordinate2D, discipline: Discipline) {
        self.discipline = discipline
        super.init()
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    init?(fromJSON json: [String: Any]) {
        guard let subtitle = json[Keys.subtitle] as? String,
            let type = json[Keys.type] as? String,
            let discipline = Discipline(from: type),
            let latitudeString = json[Keys.latitude] as? String,
            let longitudeString = json[Keys.longitude] as? String else {
                return nil
        }
        self.discipline = discipline
        super.init()
        self.title = json[Keys.title] as? String
        self.subtitle = subtitle
        let latitude = Double(Place.matches(for: "\\d+(\\.\\d+)?", in: latitudeString)[0])!
        let longitude = Double(Place.matches(for: "\\d+(\\.\\d+)?", in: longitudeString)[0])! * (-1)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }


    // MARK: Helpers

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
