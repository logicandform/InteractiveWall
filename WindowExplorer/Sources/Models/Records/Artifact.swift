//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum ArtifactType {
    case archival
    case library
    case museum
    case resource
    case rg10

    init?(string: String?) {
        switch string?.lowercased() {
        case "archival item":
            self = .archival
        case "library item":
            self = .library
        case "museum work":
            self = .museum
        case "resource":
            self = .resource
        case "rg10 file":
            self = .rg10
        default:
            return nil
        }
    }
}


final class Artifact: Record {

    let artifactType: ArtifactType?

    private struct Keys {
        static let artifactType = "artifactType"
    }


    // MARK: Init

    init?(json: JSON) {
        let artifactType = ArtifactType(string: json[Keys.artifactType] as? String)
        self.artifactType = artifactType
        super.init(type: .artifact, json: json)
        if artifactType == .rg10 {
            for page in media {
                page.type = .rg10
            }
        }
    }
}
