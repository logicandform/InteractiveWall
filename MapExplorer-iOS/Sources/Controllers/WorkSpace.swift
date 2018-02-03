// Copyright © 2017 JABT Labs Inc. All rights reserved.

import UIKit
import Foundation
import C4
import MONode

class WorkSpace: CanvasController {
    var currentUniverse: UniverseController?
    var syncTimestamp: TimeInterval = 0
    var loading: View!
    var map = Map()


    var preparing: Bool = false

    override func setup() {
        currentUniverse = map
        canvas.add(currentUniverse?.canvas)
    }


    

    func selectUniverse(_ name: String) -> UniverseController? {
        switch name {
        case "Map":
            return map
        default:
            return nil
        }
    }
}

