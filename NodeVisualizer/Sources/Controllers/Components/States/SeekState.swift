//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SeekState: GKState {

    private(set) unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

//        if case let .seekRecordAgent(targetAgent) = entity.mandate {
//            if entity.distance(to: targetAgent) < 100 {
//                entity.agent.behavior = RecordEntityBehavior.behavior(toSeek: targetAgent, withTargetSpeed: 0.001, avoid: entity.agentsToSeparateFrom)
//                stateMachine?.enter(ConnectedState.self)
//            } else {
//                entity.agent.behavior = RecordEntityBehavior.behavior(toSeek: targetAgent)
//            }
//        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SeekState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }

}







