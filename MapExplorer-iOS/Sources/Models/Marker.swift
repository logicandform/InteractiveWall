// Copyright © 2017 JABT Labs Inc. All rights reserved.

import Foundation
import MapKit

class Marker: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String?, locName: String, type: String, lat: String, lon: String){
        /*
        if title != nil{
            self.title = title
        }
        else {self.title = nil}
 */
        self.title = locName
        self.locationName = locName
        self.discipline = type
        let latitude = Double(Marker.matches(for: "\\d+(\\.\\d+)?", in: lat)[0])!
        let longitude = Double(Marker.matches(for: "\\d+(\\.\\d+)?", in: lon)[0])! * (-1)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        super.init()
    }
    
    override var description: String {
        return locationName + " " + String(describing: coordinate)
    }
    
    var markerTintColor: UIColor {
        switch discipline {
        case "School":
            return UIColor(red:0.93, green:0.00, blue:0.18, alpha:1.0)
        case "Event":
            return UIColor(red:0.24, green:0.07, blue:0.69, alpha:1.0)
        case "Hearing":
            return UIColor(red:0.58, green:0.01, blue:0.65, alpha:1.0)
        default:
            return .black
        }
    }
    
    var imageName: String? {
        return discipline
    }
    
    static func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
