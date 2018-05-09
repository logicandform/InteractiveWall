//  Copyright © 2018 JABT. All rights reserved.

import Foundation

final class GeocodeHelper {

    static let instance = GeocodeHelper()

    private var provinceSchoolMapping = [String: [School]]() // TODO: change String type to the Province Enum type --> Tim's branch


    // Use singleton instance
    private init() { }


    // MARK: API

//     associateProvinceToSchools

    // TODO: change province: String to province: Province Enum
    func getAllSchools(correspondingTo province: String) -> [School] {
        // check that the province key exists in our mapping variable
        // get schools corresponding to the province

        guard let schools = provinceSchoolMapping[province] else {
            return []
        }

        return schools
    }


    // MARK: Helpers









}

