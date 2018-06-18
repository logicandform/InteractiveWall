//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class RecordEntityBehavior: GKBehavior {

    static func behavior(for agent: GKAgent2D, toSeek seekAgent: GKAgent2D) -> GKBehavior {
        let behavior = RecordEntityBehavior()
        behavior.addAgentSeekGoal(seek: seekAgent)
        return behavior
    }


    private func addAgentSeekGoal(seek: GKAgent2D) {
        setWeight(1, for: GKGoal(toSeekAgent: seek))
    }





}





