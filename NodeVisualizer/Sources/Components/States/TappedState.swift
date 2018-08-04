//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A RecordEntity enters this state when the user has tapped on its node in the scene. 
 */

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // Physics
        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        if let cluster = entity.cluster, stateMachine?.currentState is TappedState {
            entity.animationComponent.requestedAnimationState = .goToPoint(cluster.center)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }
}
