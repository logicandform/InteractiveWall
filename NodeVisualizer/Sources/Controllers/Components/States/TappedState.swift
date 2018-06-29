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

        let relatedEntities = getRelatedEntites()
        entity.relatedEntities = relatedEntities

        // reset
        resetEntityAndRelatedEntities()

        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        // because we reset for all related entities and its own, make sure that we set hasReset to false before performing movements and animations
        entity.hasReset = false

        // request animation to make the tapped entity go to a point
        if let sceneFrame = entity.renderComponent.recordNode.scene?.frame {
            let centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)
            entity.animationComponent.requestedAnimationState = .goToPoint(centerPoint)
        }

        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        for relatedEntity in relatedEntities {
            relatedEntity.movementComponent.entityToSeek = entity
            relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is SeekState.Type, is WanderState.Type:
            return true
        default:
            return false
        }
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

    private func resetEntityAndRelatedEntities() {
        guard let scene = entity.renderComponent.recordNode.scene as? MainScene, let currentEntityInFocus = scene.currentEntityInFocus else {
            return
        }

        currentEntityInFocus.reset()
    }
}
