//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit
import CoreLocation

final class GeocodeHelper {

    static let instance = GeocodeHelper()

    private var provinceSchoolMapping = [String: [School]]()
    private var geoCodeTimer: Timer?
    private lazy var geocoder = CLGeocoder()


    // Use singleton instance
    private init() { }


    // MARK: API

    func getAllSchools(correspondingTo province: Province) -> [School]? {
        let key = province.abbreviation
        guard let schools = provinceSchoolMapping[key] else {
            return nil
        }
        return schools
    }

    func associateSchoolsToProvinces() {
        SchoolFactory.getAllSchools { [weak self] (schools) in
            guard let schools = schools, let schoolsWithLatLong = self?.filter(schools) else {
                return
            }

            self?.geoCode(schoolsWithLatLong, then: { (dict) in
                self?.provinceSchoolMapping = dict
                print("completed")
            })
        }
    }


    // MARK: Helpers

    private func filter(_ schools: [School]) -> [School] {
        return schools.filter {
            $0.coordinate != nil
        }
    }

    /// Reverse geocode school's coordinates to its associated province
    private func geoCode(_ schools: [School], with results: [String: [School]] = [:], then completionHandler: @escaping ([String: [School]]) -> ()) {
        guard let school = schools.first,
            let latitude = school.coordinate?.latitude,
            let longitude = school.coordinate?.longitude else {
                completionHandler(results)
                return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            var updatedResults = results

            if let error = error {
                print(error.localizedDescription)
                self?.geoCodeTimer?.invalidate()
                self?.geoCodeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] (timer) in
                    self?.geoCode(schools, with: results, then: completionHandler)
                })

            } else if let placemark = placemarks?.first {

                if let province = placemark.administrativeArea {
                    if let _  = updatedResults[province] {
                        updatedResults[province]?.append(school)
                    } else {
                        updatedResults[province] = [school]
                    }
                }

                let remainingSchools = Array(schools[1..<schools.count])
                self?.geoCode(remainingSchools, with: updatedResults, then: completionHandler)
            }
        }
    }

    /// Gets Provinces of the school in batches (can setup timer..not sure if necessary)
    private func getProvinces(of schoolBatches: [[School]], then completionHandler: @escaping () -> ()) {
        guard let schoolBatch = schoolBatches.first else {
            completionHandler()
            return
        }

        geoCode(schoolBatch) { (dict) in
            // dict
            let remainingSchoolBatches = Array(schoolBatches[1..<schoolBatches.count])
            self.getProvinces(of: remainingSchoolBatches, then: completionHandler)
        }
    }

}

private extension GeocodeHelper {
    class SchoolFactory {
        static func getAllSchools(then completionHandler: @escaping ([School]?) -> Void) {
            firstly {
                try CachingNetwork.getSchools()
            }.then { schools in
                completionHandler(schools)
            }.catch { error in
                print(error.localizedDescription)
                completionHandler(nil)
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
