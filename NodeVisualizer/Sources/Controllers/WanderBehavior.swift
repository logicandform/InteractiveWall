//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class WanderBehavior: GKBehavior {

    init(wander: Float) {
        super.init()

        let wanderGoal = GKGoal(toWander: wander)
        setWeight(0.5, for: wanderGoal)
    }


}

