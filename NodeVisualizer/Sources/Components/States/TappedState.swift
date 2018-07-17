//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    private unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // physics
        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        // request animation to make the tapped entity go to a point
        if let sceneFrame = entity.renderComponent.recordNode.scene?.frame {
            let centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)
            entity.animationComponent.requestedAnimationState = .goToPoint(centerPoint)
        }

        // move the tapped entity and all of its descendants to the appropriate state
        let entitiesInLevel = EntityManager.instance.entitiesInLevel

        for (level, entities) in entitiesInLevel.enumerated() {
            if let nodeBoundingEntity = NodeBoundingManager.instance.nodeBoundingEntityForLevel[level],
                let boundingNode = nodeBoundingEntity.nodeBoundingRenderComponent.node {
                for entity in entities {
                    entity.physicsComponent.physicsBody.categoryBitMask = boundingNode.physicsBody!.categoryBitMask
                    entity.physicsComponent.physicsBody.collisionBitMask = boundingNode.physicsBody!.collisionBitMask
                    entity.physicsComponent.physicsBody.contactTestBitMask = boundingNode.physicsBody!.contactTestBitMask

                    entity.movementComponent.entityToSeek = self.entity
                    entity.intelligenceComponent.stateMachine.enter(SeekState.self)
                }
            }
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
