//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Theme: Record {


    // MARK: Init

    init?(json: JSON) {
        super.init(type: .theme, json: json)
    }
}
