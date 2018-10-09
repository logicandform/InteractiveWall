//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Event: Record {


    // MARK: Init

    init?(json: JSON) {
        super.init(type: .event, json: json)
    }
}
