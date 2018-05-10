//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import CoreLocation

final class GeocodeHelper {

    static let instance = GeocodeHelper()

    private enum RequestState {
        case next
        case retry(school: School)
    }

    private(set) var provinceForSchool = [String: Set<School>]()
    private lazy var schools = Set<School>()
    private lazy var geocoder = CLGeocoder()


    // Use singleton instance
    private init() { }


    // MARK: API

    func associateSchoolsToProvinces() {
        RecordFactory.records(for: .school) { [weak self] schools in
            guard let schools = schools as? [School] else {
                return
            }

            self?.schools = Set(schools)
            self?.handle(.next)
        }
    }


    // MARK: Helpers

    private func handle(_ state: RequestState) {
        switch state {
        case .next:
            guard let school = schools.popFirst() else {
                return
            }
            reverseGeocode(school)

        case .retry(let school):
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
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
            self?.mapProvince(for: school, with: placemarks, error)
        }
    }

    private func mapProvince(for school: School, with placemarks: [CLPlacemark]?, _ error: Error?) {
        if let _ = error {
            handle(.retry(school: school))

        } else if let placemark = placemarks?.first {
            if let province = placemark.administrativeArea {
                if let _  = provinceForSchool[province] {
                    provinceForSchool[province]?.insert(school)
                } else {
                    provinceForSchool[province] = [school]
                }
            }

            handle(.next)
        }
    }
}
