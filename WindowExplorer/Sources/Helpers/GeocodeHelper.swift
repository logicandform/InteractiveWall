//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import CoreLocation

final class GeocodeHelper {

    static let instance = GeocodeHelper()

    private(set) var provinceForSchool = [String: Set<School>]()
    private lazy var schools = Set<School>()
    private var requestTimer: Timer?
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
            self?.getNewProvince()
        }
    }


    // MARK: Helpers

    private func getNewProvince() {
        guard let school = schools.popFirst() else {
            return
        }
        
        reverseGeocode(school)
    }

    private func retryProvince(for school: School) {
        requestTimer?.invalidate()
        requestTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            self?.reverseGeocode(school)
        })
    }

    private func reverseGeocode(_ school: School) {
        guard let latitude = school.coordinate?.latitude, let longitude = school.coordinate?.longitude else {
            // because not filtering beforehand, if there is no coordinate for a school, just get the next province
            getNewProvince()
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            self?.mapProvince(for: school, with: placemarks, error)
        }
    }

    private func mapProvince(for school: School, with placemarks: [CLPlacemark]?, _ error: Error?) {
        if let error = error {
            // maximum number of requests made, so request with same school
            print(error.localizedDescription)
            retryProvince(for: school)

        } else if let placemark = placemarks?.first {
            if let province = placemark.administrativeArea {
                if let _  = provinceForSchool[province] {
                    provinceForSchool[province]?.insert(school)
                } else {
                    provinceForSchool[province] = [school]
                }
            }
            
            getNewProvince()
        }
    }
}
