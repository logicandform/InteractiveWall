//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    private(set) unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        // run animation to go to center of screen
        if let sceneFrame = entity.renderComponent.recordNode.scene?.frame {
            let centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)
            entity.animationComponent.requestedAnimationState = .goToPoint(centerPoint)
        }

        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        let relatedEntities = getRelatedEntites()
        entity.relatedEntities = relatedEntities

        handleRelatedEntities()

        for case let relatedEntity in relatedEntities {
            relatedEntity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1
            relatedEntity.movementComponent.entityToSeek = entity
            relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SeekState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }


    // MARK: Helpers

    private func getRelatedEntites() -> [RecordEntity] {
        let record = entity.renderComponent.recordNode.record
        guard let relatedRecords = TestingEnvironment.instance.relatedRecordsForRecord[record] else {
            return []
        }

        let relatedEntities = entity.manager.entities(for: Array(relatedRecords)).compactMap({ $0 as? RecordEntity })

        return relatedEntities
    }

    private func handleRelatedEntities() {
        let relatedEntitiesToCurrentTappedEntity = entity.relatedEntities

        for relatedEntity in relatedEntitiesToCurrentTappedEntity {
            relatedEntity.intelligenceComponent.stateMachine.enter(WanderState.self)
            relatedEntity.renderComponent.recordNode.removeAllActions()
            relatedEntity.physicsComponent.physicsBody.isDynamic = true

            for relatedRelatedEntity in relatedEntity.relatedEntities {
                if relatedRelatedEntity != entity {
                    relatedRelatedEntity.physicsComponent.physicsBody.isDynamic = true
                    relatedRelatedEntity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 0
                    relatedRelatedEntity.intelligenceComponent.stateMachine.enter(WanderState.self)
                    relatedRelatedEntity.movementComponent.entityToSeek = nil
                    relatedRelatedEntity.renderComponent.recordNode.removeAllActions()
                }
            }
        }
    }
}
