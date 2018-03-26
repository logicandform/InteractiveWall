//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Theme {

    let id: Int
    let title: String
    let description: String?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let description = "description"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = (json[Keys.description] as? String)?.removingHtml()
    }
}
