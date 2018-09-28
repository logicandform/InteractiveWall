//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Individual: Record {


    // MARK: Init

    init?(json: JSON) {
        super.init(type: .individual, json: json)
    }
}
