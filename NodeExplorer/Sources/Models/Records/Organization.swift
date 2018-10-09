//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Organization: Record {


    // MARK: Init

    init?(json: JSON) {
        super.init(type: .organization, json: json)
    }
}
