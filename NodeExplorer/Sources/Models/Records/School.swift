//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class School: Record {


    // MARK: Init

    init?(json: JSON) {
        super.init(type: .school, json: json)
    }
}
