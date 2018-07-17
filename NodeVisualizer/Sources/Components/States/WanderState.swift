//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class WanderState: GKState {

    private unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        entity.physicsComponent.physicsBody.friction = 1
        entity.physicsComponent.physicsBody.linearDamping = 1
        entity.physicsComponent.physicsBody.isDynamic = true
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 0

        entity.physicsComponent.physicsBody.categoryBitMask = 0xFFFFFFFF
        entity.physicsComponent.physicsBody.collisionBitMask = 0xFFFFFFFF
        entity.physicsComponent.physicsBody.contactTestBitMask = 0xFFFFFFFF

        entity.renderComponent.recordNode.removeAllActions()
        entity.movementComponent.entityToSeek = nil

        entity.hasCollidedWithBoundingNode = false
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
