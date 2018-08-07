//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A RecordEntity enters this state when it seeks the TappedState's RecordEntity.
class SeekTappedEntityState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // sticky collisions
        entity.physicsBody.restitution = 0
        entity.physicsBody.friction = 1
        entity.physicsBody.linearDamping = 1

        // interactable with rest of physics world
        entity.physicsBody.isDynamic = true

        // not interactable with the repulsive 'reset' radial force field
        entity.physicsBody.fieldBitMask = 0x1 << 1
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
