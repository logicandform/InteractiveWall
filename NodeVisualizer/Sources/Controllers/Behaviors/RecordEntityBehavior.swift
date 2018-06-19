//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


class RecordEntityBehavior: GKBehavior {

    static func behavior(toSeek agent: GKAgent2D?) -> GKBehavior {
        let behavior = RecordEntityBehavior()
        behavior.addAgentSeekGoal(agent: agent)
        return behavior
    }


    private func addAgentSeekGoal(agent: GKAgent2D?) {
        if let agent = agent {
            setWeight(1, for: GKGoal(toSeekAgent: agent))
        }
    }
}
