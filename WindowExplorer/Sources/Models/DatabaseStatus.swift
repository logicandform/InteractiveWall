//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct DatabaseStatus: Equatable {

    let refreshing: Bool
    let error: Bool
    let description: String

    private struct Keys {
        static let error = "error"
        static let refreshing = "refreshing"
        static let description = "description"
    }


    // MARK: Init

    init(refreshing: Bool, error: Bool, description: String) {
        self.refreshing = refreshing
        self.error = error
        self.description = description
    }

    init?(json: JSON) {
        guard let refreshing = json[Keys.refreshing] as? Bool, let error = json[Keys.error] as? Bool, let description = json[Keys.description] as? String else {
            return nil
        }

        self.refreshing = refreshing
        self.error = error
        self.description = description
    }
}
