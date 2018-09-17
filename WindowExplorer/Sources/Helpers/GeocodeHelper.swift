//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import CoreLocation


final class GeocodeHelper {

    static let instance = GeocodeHelper()

    private var schoolsForProvince = [Province: Set<School>]()
    private var schools = Set<School>()
    private let geocoder = CLGeocoder()

    private enum RequestState {
        case next
        case retry(school: School)
    }

    private struct Constants {
        static let delay: TimeInterval = 5
        static let userDefaultsKey = "ProvinceForCoordinateKey"
    }


    // Use singleton instance
    private init() { }


    // MARK: API

    func associateSchoolsToProvinces() {
        if let schoolRecords = RecordManager.instance.records(for: .school) as? [School] {
            schools = Set(schoolRecords)
            handle(.next)
        }
    }

    func schools(for province: Province) -> [School] {
        guard let schools = schoolsForProvince[province] else {
            return []
        }

        return Array(schools)
    }


    // MARK: Helpers

    private func handle(_ state: RequestState) {
        switch state {
        case .next:
            if let school = schools.popFirst() {
                if let province = province(for: school.coordinate) {
                    add(school, to: province)
                    handle(.next)
                } else {
                    reverseGeocode(school)
                }
            }
        case .retry(let school):
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.delay) { [weak self] in
                self?.reverseGeocode(school)
            }
        }
    }

    private func reverseGeocode(_ school: School) {
        guard let latitude = school.coordinate?.latitude, let longitude = school.coordinate?.longitude else {
            handle(.next)
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            self?.extractProvince(for: school, with: placemarks, error)
        }
    }

    private func extractProvince(for school: School, with placemarks: [CLPlacemark]?, _ error: Error?) {
        if error != nil {
            handle(.retry(school: school))
        } else if let placemark = placemarks?.first {
            if let area = placemark.administrativeArea, let province = Province(abbreviation: area) {
                add(school, to: province)
                store(province, for: school.coordinate)
            }

            handle(.next)
        }
    }

    private func add(_ school: School, to province: Province) {
        if schoolsForProvince[province] != nil {
            schoolsForProvince[province]?.insert(school)
        } else {
            schoolsForProvince[province] = [school]
        }
    }

    /// Stores the province for a coordinate into UserDefaults
    private func store(_ province: Province, for coordinate: CLLocationCoordinate2D?) {
        guard let coordinate = coordinate else {
            return
        }

        var provinceForCoordinate = UserDefaults.standard.object(forKey: Constants.userDefaultsKey) as? JSON ?? [:]
        if var latitudeInfo = provinceForCoordinate[coordinate.latitude.description] as? JSON {
            latitudeInfo[coordinate.longitude.description] = province.abbreviation
            provinceForCoordinate[coordinate.latitude.description] = latitudeInfo
        } else {
            provinceForCoordinate[coordinate.latitude.description] = [coordinate.longitude.description: province.abbreviation]
        }

        UserDefaults.standard.set(provinceForCoordinate, forKey: Constants.userDefaultsKey)
    }

    /// Attempts to get the province for a coordinate from UserDefaults
    private func province(for coordinate: CLLocationCoordinate2D?) -> Province? {
        guard let coordinate = coordinate,
            let coordinateInfo = UserDefaults.standard.object(forKey: Constants.userDefaultsKey) as? JSON,
            let latitudeInfo = coordinateInfo[coordinate.latitude.description] as? JSON,
            let abbreviation = latitudeInfo[coordinate.longitude.description] as? String else {
            return nil
        }

        return Province(abbreviation: abbreviation)
    }
}
