//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SeekState: GKState {

    unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

//        entity.renderComponent.recordNode.physicsBody?.fieldBitMask = 0x1 << 1
        entity.physicsComponent.setFieldBitMask(bitmask: 0x1 << 1)

//        entity.component(ofType: RecordAgent.self)?.behavior = entity.behaviorForCurrentMandate
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
        return stateClass is ConnectedState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)

        entity.agent.behavior = nil
    }


    private func stopMovement(afterTraversing distance: Float) {
        let timeToTarget = TimeInterval(distance / entity.agent.speed)
        Timer.scheduledTimer(withTimeInterval: timeToTarget, repeats: false) { _ in
            self.entity.agent.behavior = nil
            self.entity.agent.behavior = RecordEntityBehavior.stop()
            self.entity.agent.maxSpeed = 0
        }
    }
}
