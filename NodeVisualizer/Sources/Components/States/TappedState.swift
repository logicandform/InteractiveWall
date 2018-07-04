//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    private(set) unowned var entity: RecordEntity

    private var entitiesInLevel = [[RecordEntity]]()
    private var entitiesInCurrentLevel = [RecordEntity]()
    private var elapsedTime: TimeInterval = 0.0
    private var levelFormationDuration: TimeInterval = 0.0
    private var centerPoint: CGPoint = .zero


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // reset
        entity.manager.reset()

        // make level connections for all the entity's descendants
        entity.manager.associateRelatedEntities(for: [entity])
        entitiesInLevel = entity.manager.entitiesInLevel.reversed()

        // physics
        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        // request animation to make the tapped entity go to a point
        if let sceneFrame = entity.renderComponent.recordNode.scene?.frame {
            centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)
            entity.animationComponent.requestedAnimationState = .goToPoint(centerPoint)
        }

        guard let relatedEntities = entitiesInLevel.popLast() else {
            return
        }

        entitiesInCurrentLevel = relatedEntities

        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        for relatedEntity in relatedEntities {
            relatedEntity.movementComponent.entityToSeek = entity
            relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        elapsedTime += seconds

        if elapsedTime >= 8 {
            var maximumDistance: CGFloat = 0.0

            // find the maximum radius between the tapped root node and its descendants for the current level
            for relatedEntity in entitiesInCurrentLevel {
                let distance = entity.distance(to: relatedEntity)
                if distance > maximumDistance {
                    maximumDistance = distance
                }
            }

            maximumDistance += NodeConfiguration.Record.physicsBodyRadius * 4

            // get the next level's related entities and move them to the appropriate state with the maximum radius constraint
            if let relatedEntities = entitiesInLevel.popLast() {
                entitiesInCurrentLevel = relatedEntities

                for relatedEntity in relatedEntities {
                    relatedEntity.movementComponent.entityToSeek = entity
                    relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)

                    let distanceConstraint = SKConstraint.distance(SKRange(lowerLimit: maximumDistance), to: centerPoint)
                    relatedEntity.renderComponent.recordNode.constraints = [distanceConstraint]
                }
            }

            // update the levelFormationDuration depending on the next level's entities


            // reset elapsedTime
            elapsedTime = 0.0
        }
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
