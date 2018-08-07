//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A RecordEntity enters this state when the user has tapped on its node in the scene.
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
        entity.physicsBody.isDynamic = false
        entity.physicsBody.fieldBitMask = 0x1 << 1

        if let cluster = entity.cluster, stateMachine?.currentState is TappedState {
            entity.set(state: .goToPoint(cluster.center))
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
