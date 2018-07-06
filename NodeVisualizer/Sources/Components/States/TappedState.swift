//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    private unowned var entity: RecordEntity

    private var entitiesInLevel = [[RecordEntity]]()
    private var entitiesInCurrentLevel = [RecordEntity]()
    private var elapsedTime: TimeInterval = 0.0
    private var levelFormationDuration: TimeInterval = 0.0
    private var currentLevel: Int = 0


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // reset the amount of time
        elapsedTime = 0.0
        levelFormationDuration = 0.0
        currentLevel = 0
        entitiesInLevel = []
        entitiesInCurrentLevel = []

        // make level connections for all the entity's descendants
        EntityManager.instance.associateRelatedEntities(for: [entity])

        // reversed so that we can use popLast
        entitiesInLevel = EntityManager.instance.entitiesInLevel.reversed()

        // physics
        entity.physicsComponent.physicsBody.isDynamic = false
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1

        // request animation to make the tapped entity go to a point
        if let sceneFrame = entity.renderComponent.recordNode.scene?.frame {
            let centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)
            entity.animationComponent.requestedAnimationState = .goToPoint(centerPoint)
        }

        // get the related entities for the first level
        guard let relatedEntities = entitiesInLevel.popLast() else {
            return
        }
        entitiesInCurrentLevel = relatedEntities
        currentLevel += 1

        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        for relatedEntity in entitiesInCurrentLevel {
            relatedEntity.physicsComponent.physicsBody.categoryBitMask = 0x1 << 0
            relatedEntity.physicsComponent.physicsBody.collisionBitMask = 0x1 << 0

            relatedEntity.movementComponent.entityToSeek = entity
            relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard !entitiesInLevel.isEmpty else {
            return
        }

        elapsedTime += seconds

        if elapsedTime >= 10 {
            var maximumDistance: CGFloat = 0.0

            // find the maximum radius between the tapped root node and its descendants for the current level
            for relatedEntity in entitiesInCurrentLevel {
                let distance = entity.distance(to: relatedEntity)
                if distance > maximumDistance {
                    maximumDistance = distance
                }
            }

            maximumDistance += NodeConfiguration.Record.physicsBodyRadius * 2

            // get the next level's related entities and move them to the appropriate state with the maximum radius constraint
            if let relatedEntities = entitiesInLevel.popLast() {
                entitiesInCurrentLevel = relatedEntities

                if let boundingNode = entity.renderComponent.boundingDiameterNode(forRadius: maximumDistance, level: currentLevel) {
                    for relatedEntity in relatedEntities {
                        relatedEntity.physicsComponent.physicsBody.categoryBitMask = boundingNode.physicsBody!.categoryBitMask
                        relatedEntity.physicsComponent.physicsBody.collisionBitMask = boundingNode.physicsBody!.collisionBitMask

                        relatedEntity.movementComponent.entityToSeek = entity
                        relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
                    }
                }

                currentLevel += 1
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

}
