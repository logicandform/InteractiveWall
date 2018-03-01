//  Copyright © 2018 JABT. All rights reserved.

import Foundation

extension URL {

    static func from(_ string: String?) -> URL? {
        guard let value = string else {
            return nil
        }

        return URL(string: value)
    }
}
